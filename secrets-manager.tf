##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

# Secrets saving
resource "aws_secretsmanager_secret" "user_login" {
  for_each = {
    for k, v in local.user_console_access : k => v
    if var.secrets_manager_store
  }
  name = "${local.secret_store_path}/iam-user/console-password/${each.value.name}"
  tags = local.all_tags
}

resource "aws_secretsmanager_secret_version" "user_login" {
  for_each = {
    for k, v in local.user_console_access : k => v
    if var.secrets_manager_store
  }
  secret_id     = aws_secretsmanager_secret.user_login[each.key].id
  secret_string = aws_iam_user_login_profile.this[each.key].encrypted_password
}

resource "aws_secretsmanager_secret" "access_keys_id" {
  for_each = {
    for k, v in local.user_access_keys : k => v
    if var.secrets_manager_store
  }
  name = "${local.secret_store_path}/iam-user/${each.value.user_name}/${each.value.key_name}/access-key-id"
  tags = local.all_tags
}

resource "aws_secretsmanager_secret_version" "access_keys_id" {
  for_each = {
    for k, v in local.user_access_keys : k => v
    if var.secrets_manager_store
  }
  secret_id     = aws_secretsmanager_secret.access_keys_id[each.key].id
  secret_string = aws_iam_access_key.this[each.key].id
}

resource "aws_secretsmanager_secret" "access_keys" {
  for_each = {
    for k, v in local.user_access_keys : k => v
    if var.secrets_manager_store
  }
  name = "${local.secret_store_path}/iam-user/${each.value.user_name}/${each.value.key_name}/access-key-secret"
  tags = local.all_tags
}

resource "aws_secretsmanager_secret_version" "access_keys" {
  for_each = {
    for k, v in local.user_access_keys : k => v
    if var.secrets_manager_store
  }
  secret_id     = aws_secretsmanager_secret.access_keys[each.key].id
  secret_string = aws_iam_access_key.this[each.key].secret
}

resource "aws_secretsmanager_secret" "access_keys_smtp" {
  for_each = {
    for k, v in local.user_access_keys : k => v
    if var.secrets_manager_store
  }
  name = "${local.secret_store_path}/iam-user/${each.value.user_name}/${each.value.key_name}/ses-smtp-password"
  tags = local.all_tags
}

resource "aws_secretsmanager_secret_version" "access_keys_smtp" {
  for_each = {
    for k, v in local.user_access_keys : k => v
    if var.secrets_manager_store
  }
  secret_id     = aws_secretsmanager_secret.access_keys[each.key].id
  secret_string = aws_iam_access_key.this[each.key].ses_smtp_password_v4
}

