"""AWS Secrets Manager rotation Lambda for IAM user access keys.

The function implements the Secrets Manager rotation protocol for module-managed
IAM users. It writes replacement access key material only to Secrets Manager. If
PGP is configured for a user, the secret access key is PGP-encrypted before it is
stored; attach a Lambda layer that provides the `pgpy` package when PGP is used.
"""

import datetime
import json
import os

import boto3
from botocore.exceptions import ClientError

try:
    import pgpy
except ImportError:  # PGP is optional unless configured for a rotated user.
    pgpy = None

secretsmanager = boto3.client("secretsmanager")
iam = boto3.client("iam")

CONFIG_SECRET_ID = os.environ["ROTATION_CONFIG_SECRET_ID"]


def handler(event, context):
    """Dispatch a Secrets Manager rotation step."""
    secret_id = event["SecretId"]
    token = event["ClientRequestToken"]
    step = event["Step"].replace("_", "").lower()

    metadata = secretsmanager.describe_secret(SecretId=secret_id)
    if not metadata.get("RotationEnabled"):
        raise ValueError(f"Secret {secret_id} is not enabled for rotation")

    versions = metadata.get("VersionIdsToStages", {})
    if token not in versions:
        raise ValueError(f"Secret version {token} has no stage for {secret_id}")
    if "AWSCURRENT" in versions[token]:
        return
    if "AWSPENDING" not in versions[token]:
        raise ValueError(f"Secret version {token} is not staged as AWSPENDING")

    config = _load_config()
    user_name, user_config = _user_config_for_secret(config, secret_id, metadata)

    if step == "createsecret":
        _create_secret(secret_id, token, user_name, user_config, config)
    elif step == "setsecret":
        _set_secret(secret_id, token)
    elif step == "testsecret":
        _test_secret(secret_id, token, user_name)
    elif step == "finishsecret":
        _finish_secret(secret_id, token, user_name, config)
    else:
        raise ValueError(f"Unsupported rotation step: {event['Step']}")


def _load_config():
    response = secretsmanager.get_secret_value(SecretId=CONFIG_SECRET_ID)
    return json.loads(response.get("SecretString") or "{}")


def _user_config_for_secret(config, secret_id, metadata):
    secret_arn = metadata.get("ARN", secret_id)
    secret_name = metadata.get("Name", secret_id)
    for user_name, user_config in config.get("users", {}).items():
        candidates = {
            value
            for value in [
                user_config.get("secret_id"),
                user_config.get("secret_arn"),
                user_config.get("secret_name"),
            ]
            if value
        }
        if secret_id in candidates or secret_arn in candidates or secret_name in candidates:
            return user_name, user_config
    raise ValueError(f"No rotation config entry found for secret {secret_id}")


def _create_secret(secret_id, token, user_name, user_config, config):
    if _version_exists(secret_id, token, "AWSPENDING"):
        return

    current_secret = _get_secret_json(secret_id, "AWSCURRENT")
    rotate_after_days = int(config.get("rotate_after_days", 90))
    if current_secret and not _rotation_due(current_secret, rotate_after_days):
        pending_secret = dict(current_secret)
        pending_secret["rotation_noop"] = True
        pending_secret["rotation_checked_at"] = _now().isoformat()
        secretsmanager.put_secret_value(
            SecretId=secret_id,
            ClientRequestToken=token,
            SecretString=json.dumps(pending_secret, default=str),
            VersionStages=["AWSPENDING"],
        )
        return

    _cleanup_old_keys(user_name, current_secret, config)
    keys = _list_access_keys(user_name)
    if len(keys) >= 2:
        raise RuntimeError(f"IAM user {user_name} already has two access keys")

    new_key = iam.create_access_key(UserName=user_name)["AccessKey"]
    try:
        pending_secret = _secret_payload(user_name, new_key, current_secret, user_config)
        secretsmanager.put_secret_value(
            SecretId=secret_id,
            ClientRequestToken=token,
            SecretString=json.dumps(pending_secret, default=str),
            VersionStages=["AWSPENDING"],
        )
    except Exception:
        iam.delete_access_key(UserName=user_name, AccessKeyId=new_key["AccessKeyId"])
        raise


def _set_secret(secret_id, token):
    # IAM access keys become active when created. This step verifies the pending
    # version exists and intentionally performs no additional external mutation.
    _get_secret_json(secret_id, "AWSPENDING", token)


def _test_secret(secret_id, token, user_name):
    pending_secret = _get_secret_json(secret_id, "AWSPENDING", token)
    access_key_id = pending_secret["access_key_id"]

    if pending_secret.get("pgp") == "yes":
        keys = _list_access_keys(user_name)
        if not any(key["AccessKeyId"] == access_key_id and key["Status"] == "Active" for key in keys):
            raise RuntimeError(f"Pending PGP-encrypted key {access_key_id} is not active")
        return

    secret_access_key = pending_secret.get("secret_access_key")
    if not secret_access_key:
        raise RuntimeError("Pending secret is missing secret_access_key")

    sts = boto3.client(
        "sts",
        aws_access_key_id=access_key_id,
        aws_secret_access_key=secret_access_key,
    )
    sts.get_caller_identity()


def _finish_secret(secret_id, token, user_name, config):
    metadata = secretsmanager.describe_secret(SecretId=secret_id)
    current_version = None
    for version, stages in metadata.get("VersionIdsToStages", {}).items():
        if "AWSCURRENT" in stages:
            if version == token:
                return
            current_version = version
            break

    secretsmanager.update_secret_version_stage(
        SecretId=secret_id,
        VersionStage="AWSCURRENT",
        MoveToVersionId=token,
        RemoveFromVersionId=current_version,
    )

    current_secret = _get_secret_json(secret_id, "AWSCURRENT")
    _cleanup_old_keys(user_name, current_secret, config)


def _get_secret_json(secret_id, version_stage, version_id=None):
    try:
        kwargs = {"SecretId": secret_id, "VersionStage": version_stage}
        if version_id:
            kwargs["VersionId"] = version_id
        response = secretsmanager.get_secret_value(**kwargs)
        return json.loads(response.get("SecretString") or "{}")
    except ClientError as exc:
        if exc.response.get("Error", {}).get("Code") in {"ResourceNotFoundException", "InvalidRequestException"}:
            return None
        raise


def _version_exists(secret_id, version_id, version_stage):
    return _get_secret_json(secret_id, version_stage, version_id) is not None


def _secret_payload(user_name, access_key, current_secret, user_config):
    secret_access_key = access_key["SecretAccessKey"]
    pgp_key = user_config.get("pgp_key") or ""
    payload = {
        "user_name": user_name,
        "access_key_id": access_key["AccessKeyId"],
        "created_at": access_key["CreateDate"].isoformat(),
        "rotation_source": "terraform-module-aws-iam-user-groups",
        "previous_access_key_id": (current_secret or {}).get("access_key_id"),
    }

    if pgp_key:
        payload["encrypted_secret_access_key"] = _encrypt_pgp(pgp_key, secret_access_key)
        payload["pgp"] = "yes"
    else:
        payload["secret_access_key"] = secret_access_key
        payload["pgp"] = "no"

    return payload


def _encrypt_pgp(public_key_blob, value):
    if pgpy is None:
        raise RuntimeError("PGP is configured but the pgpy package is not available; attach a pgpy Lambda layer")
    public_key, _ = pgpy.PGPKey.from_blob(public_key_blob)
    message = pgpy.PGPMessage.new(value)
    return str(public_key.encrypt(message))


def _rotation_due(current_secret, rotate_after_days):
    created_at = _parse_datetime(current_secret.get("created_at"))
    if created_at is None:
        return True
    return (_now() - created_at).days >= rotate_after_days


def _cleanup_old_keys(user_name, current_secret, config):
    if not current_secret:
        return

    current_key_id = current_secret.get("access_key_id")
    grace_period_days = int(config.get("grace_period_days", 7))
    inactive_key_retention_days = int(config.get("inactive_key_retention_days", 30))
    delete_inactive_keys = _as_bool(config.get("delete_inactive_keys", False))

    for key in _list_access_keys(user_name):
        key_id = key["AccessKeyId"]
        if key_id == current_key_id:
            continue
        age_days = (_now() - key["CreateDate"]).days
        if key["Status"] == "Active" and age_days >= grace_period_days:
            iam.update_access_key(UserName=user_name, AccessKeyId=key_id, Status="Inactive")
        if delete_inactive_keys and key["Status"] == "Inactive" and age_days >= grace_period_days + inactive_key_retention_days:
            iam.delete_access_key(UserName=user_name, AccessKeyId=key_id)


def _list_access_keys(user_name):
    keys = []
    marker = None
    while True:
        kwargs = {"UserName": user_name}
        if marker:
            kwargs["Marker"] = marker
        response = iam.list_access_keys(**kwargs)
        keys.extend(response.get("AccessKeyMetadata", []))
        if not response.get("IsTruncated"):
            return sorted(keys, key=lambda item: item["CreateDate"])
        marker = response.get("Marker")


def _parse_datetime(value):
    if not value:
        return None
    parsed = datetime.datetime.fromisoformat(value.replace("Z", "+00:00"))
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=datetime.timezone.utc)
    return parsed


def _now():
    return datetime.datetime.now(datetime.timezone.utc)


def _as_bool(value):
    if isinstance(value, bool):
        return value
    return str(value).lower() in {"1", "true", "yes", "y"}
