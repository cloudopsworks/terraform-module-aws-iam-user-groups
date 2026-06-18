##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

locals {
  access_key_rotation_settings = var.access_key_rotation == null ? {} : var.access_key_rotation

  access_key_rotation_enabled                        = try(local.access_key_rotation_settings.enabled, false)
  access_key_rotation_user_allowlist                 = try(local.access_key_rotation_settings.users, [])
  access_key_rotation_group_selectors                = try(local.access_key_rotation_settings.groups, [])
  access_key_rotation_excluded_users                 = try(local.access_key_rotation_settings.exclude_users, [])
  access_key_rotation_create_secrets                 = try(local.access_key_rotation_settings.create_secrets, true)
  access_key_rotation_create_lambda                  = try(local.access_key_rotation_settings.create_lambda, true)
  access_key_rotation_lambda_arn                     = try(local.access_key_rotation_settings.lambda_arn, null)
  access_key_rotation_lambda_layer_arns              = try(local.access_key_rotation_settings.lambda_layer_arns, [])
  access_key_rotation_lambda_timeout                 = try(local.access_key_rotation_settings.lambda_timeout, 60)
  access_key_rotation_lambda_memory_size             = try(local.access_key_rotation_settings.lambda_memory_size, 256)
  access_key_rotation_rotate_after_days              = try(local.access_key_rotation_settings.rotate_after_days, 90)
  access_key_rotation_automatically_after_days       = try(local.access_key_rotation_settings.automatically_after_days, local.access_key_rotation_rotate_after_days)
  access_key_rotation_schedule_expression            = try(local.access_key_rotation_settings.schedule_expression, null)
  access_key_rotation_schedule_duration              = try(local.access_key_rotation_settings.schedule_duration, null)
  access_key_rotation_rotate_immediately             = try(local.access_key_rotation_settings.rotate_immediately, false)
  access_key_rotation_grace_period_days              = try(local.access_key_rotation_settings.grace_period_days, 7)
  access_key_rotation_inactive_key_retention_days    = try(local.access_key_rotation_settings.inactive_key_retention_days, 30)
  access_key_rotation_delete_inactive_keys           = try(local.access_key_rotation_settings.delete_inactive_keys, false)
  access_key_rotation_secret_prefix                  = trimsuffix(try(local.access_key_rotation_settings.secret_prefix, "") != "" ? local.access_key_rotation_settings.secret_prefix : "${local.secret_store_path}/iam-user/access-key-rotation", "/")
  access_key_rotation_secret_recovery_window_in_days = try(local.access_key_rotation_settings.secret_recovery_window_in_days, 30)
  access_key_rotation_secret_kms_key_id              = try(local.access_key_rotation_settings.secret_kms_key_id, null)
  access_key_rotation_provided_secret_ids            = try(local.access_key_rotation_settings.secret_arns, {})
  access_key_rotation_function_name                  = substr(try(local.access_key_rotation_settings.lambda_function_name, "") != "" ? local.access_key_rotation_settings.lambda_function_name : "${local.system_name_short}-iam-key-rotation", 0, 64)
  access_key_rotation_lambda_role_name               = substr(try(local.access_key_rotation_settings.lambda_role_name, "") != "" ? local.access_key_rotation_settings.lambda_role_name : "${local.system_name_short}-iam-key-rotation-lambda", 0, 64)
  access_key_rotation_config_secret_name             = try(local.access_key_rotation_settings.config_secret_name, "") != "" ? local.access_key_rotation_settings.config_secret_name : "${local.access_key_rotation_secret_prefix}/_rotation-config"
  access_key_rotation_log_retention_days             = try(local.access_key_rotation_settings.log_retention_days, 30)

  user_pgp_secret_ids = {
    for user in var.users : user.name => replace(user.pgp_key, "_aws:", "")
    if try(user.pgp_key, "") != "" && startswith(try(user.pgp_key, ""), "_aws:")
  }
  user_pgp_key_map = {
    for user in var.users : user.name => try(user.pgp_key, "") != "" ? (
      startswith(try(user.pgp_key, ""), "_aws:") ? try(data.aws_secretsmanager_secret_version.user_pgp_public_key[user.name].secret_string, "") : user.pgp_key
    ) : local.default_pgp_key
  }

  access_key_rotation_all_user_names = [for user in var.users : user.name]
  access_key_rotation_group_user_names = distinct(flatten([
    for user in var.users : [
      for group in try(user.groups, []) : user.name
      if contains(local.access_key_rotation_group_selectors, group)
    ]
  ]))
  access_key_rotation_user_opt_out_names = sort([
    for user in var.users : user.name
    if try(user.access_key_rotation_enabled, true) == false ||
    try(tobool(user.access_key_rotation), true) == false ||
    try(user.access_key_rotation.enabled, true) == false ||
    try(user.access_key_rotation.opt_out, false) == true
  ])
  access_key_rotation_requested_user_names = sort(tolist(setsubtract(
    toset(length(local.access_key_rotation_user_allowlist) > 0 ? local.access_key_rotation_user_allowlist : (
      length(local.access_key_rotation_group_selectors) > 0 ? local.access_key_rotation_group_user_names : local.access_key_rotation_all_user_names
    )),
    setunion(toset(local.access_key_rotation_excluded_users), toset(local.access_key_rotation_user_opt_out_names))
  )))
  access_key_rotation_target_user_names = [
    for user_name in local.access_key_rotation_requested_user_names : user_name
    if contains(keys(local.users_map), user_name)
  ]
  access_key_rotation_ignored_user_names = sort(tolist(setsubtract(
    toset(local.access_key_rotation_requested_user_names),
    toset(local.access_key_rotation_target_user_names)
  )))
  access_key_rotation_targets = {
    for user_name in local.access_key_rotation_target_user_names : user_name => local.users_map[user_name]
  }
  access_key_rotation_target_user_arns = [
    for user_name in local.access_key_rotation_target_user_names : aws_iam_user.this[user_name].arn
  ]
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_secretsmanager_secret_version" "user_pgp_public_key" {
  for_each  = local.user_pgp_secret_ids
  secret_id = each.value
}

resource "aws_secretsmanager_secret" "access_key_rotation" {
  for_each = local.access_key_rotation_enabled && local.access_key_rotation_create_secrets ? local.access_key_rotation_targets : {}

  name                    = "${local.access_key_rotation_secret_prefix}/${each.key}"
  kms_key_id              = local.access_key_rotation_secret_kms_key_id
  recovery_window_in_days = local.access_key_rotation_secret_recovery_window_in_days
  tags                    = local.all_tags
}

locals {
  access_key_rotation_created_secret_ids = {
    for user_name, secret in aws_secretsmanager_secret.access_key_rotation : user_name => secret.arn
  }
  access_key_rotation_created_secret_names = {
    for user_name, secret in aws_secretsmanager_secret.access_key_rotation : user_name => secret.name
  }
  access_key_rotation_secret_id_map = merge(
    local.access_key_rotation_provided_secret_ids,
    local.access_key_rotation_created_secret_ids
  )
  access_key_rotation_secret_name_map = merge(
    {
      for user_name, secret_id in local.access_key_rotation_provided_secret_ids : user_name => startswith(secret_id, "arn:") ? null : secret_id
    },
    local.access_key_rotation_created_secret_names
  )
  access_key_rotation_secret_resource_arn_map = {
    for user_name, secret_id in local.access_key_rotation_secret_id_map : user_name => startswith(secret_id, "arn:") ? secret_id : "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:secret:${secret_id}-*"
  }
  access_key_rotation_secret_resource_arns = values(local.access_key_rotation_secret_resource_arn_map)
  access_key_rotation_user_config_target_names = [
    for user_name in local.access_key_rotation_target_user_names : user_name
    if contains(keys(local.access_key_rotation_secret_id_map), user_name)
  ]
  access_key_rotation_user_config = {
    for user_name in local.access_key_rotation_user_config_target_names : user_name => {
      secret_id   = local.access_key_rotation_secret_id_map[user_name]
      secret_arn  = try(local.access_key_rotation_secret_resource_arn_map[user_name], null)
      secret_name = try(local.access_key_rotation_secret_name_map[user_name], null)
      pgp_key     = try(local.user_pgp_key_map[user_name], "")
      pgp_enabled = try(local.user_pgp_key_map[user_name], "") != ""
    }
  }
  access_key_rotation_pgp_enabled          = anytrue([for _, cfg in local.access_key_rotation_user_config : cfg.pgp_enabled])
  access_key_rotation_effective_lambda_arn = local.access_key_rotation_create_lambda ? try(aws_lambda_function.access_key_rotation[0].arn, null) : local.access_key_rotation_lambda_arn
}

resource "aws_secretsmanager_secret" "access_key_rotation_config" {
  count = local.access_key_rotation_enabled && local.access_key_rotation_create_lambda ? 1 : 0

  name                    = local.access_key_rotation_config_secret_name
  kms_key_id              = local.access_key_rotation_secret_kms_key_id
  recovery_window_in_days = local.access_key_rotation_secret_recovery_window_in_days
  tags                    = local.all_tags

  lifecycle {
    precondition {
      condition     = length(local.access_key_rotation_user_config) > 0
      error_message = "access_key_rotation.enabled requires at least one selected module-managed user with a Secrets Manager destination. Leave create_secrets=true or provide access_key_rotation.secret_arns."
    }
  }
}

resource "aws_secretsmanager_secret_version" "access_key_rotation_config" {
  count = local.access_key_rotation_enabled && local.access_key_rotation_create_lambda ? 1 : 0

  secret_id = aws_secretsmanager_secret.access_key_rotation_config[0].id
  secret_string = jsonencode({
    users                       = local.access_key_rotation_user_config
    rotate_after_days           = local.access_key_rotation_rotate_after_days
    grace_period_days           = local.access_key_rotation_grace_period_days
    inactive_key_retention_days = local.access_key_rotation_inactive_key_retention_days
    delete_inactive_keys        = local.access_key_rotation_delete_inactive_keys
  })
}

data "archive_file" "access_key_rotation_lambda" {
  count = local.access_key_rotation_enabled && local.access_key_rotation_create_lambda ? 1 : 0

  type        = "zip"
  source_file = "${path.module}/lambda/iam_access_key_rotation.py"
  output_path = "${path.root}/.terraform/iam_access_key_rotation_${filesha256("${path.module}/lambda/iam_access_key_rotation.py")}.zip"
}

data "aws_iam_policy_document" "access_key_rotation_lambda_assume_role" {
  count = local.access_key_rotation_enabled && local.access_key_rotation_create_lambda ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "access_key_rotation_lambda" {
  count = local.access_key_rotation_enabled && local.access_key_rotation_create_lambda ? 1 : 0

  name               = local.access_key_rotation_lambda_role_name
  assume_role_policy = data.aws_iam_policy_document.access_key_rotation_lambda_assume_role[0].json
  tags               = local.all_tags
}

data "aws_iam_policy_document" "access_key_rotation_lambda" {
  count = local.access_key_rotation_enabled && local.access_key_rotation_create_lambda ? 1 : 0

  statement {
    sid    = "WriteLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["${aws_cloudwatch_log_group.access_key_rotation_lambda[0].arn}:*"]
  }

  statement {
    sid    = "ReadRotationConfig"
    effect = "Allow"
    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue"
    ]
    resources = [aws_secretsmanager_secret.access_key_rotation_config[0].arn]
  }

  statement {
    sid    = "ManageRotatedSecrets"
    effect = "Allow"
    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
      "secretsmanager:PutSecretValue",
      "secretsmanager:UpdateSecretVersionStage"
    ]
    resources = length(local.access_key_rotation_secret_resource_arns) > 0 ? local.access_key_rotation_secret_resource_arns : [
      "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:secret:__no_rotation_targets__-*"
    ]
  }

  statement {
    sid    = "RotateSelectedUserAccessKeys"
    effect = "Allow"
    actions = [
      "iam:CreateAccessKey",
      "iam:DeleteAccessKey",
      "iam:GetUser",
      "iam:ListAccessKeys",
      "iam:UpdateAccessKey"
    ]
    resources = length(local.access_key_rotation_target_user_arns) > 0 ? local.access_key_rotation_target_user_arns : [
      "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:user/__no_rotation_targets__"
    ]
  }

  dynamic "statement" {
    for_each = local.access_key_rotation_secret_kms_key_id == null ? [] : [1]

    content {
      sid    = "UseRotationSecretKmsKey"
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:Encrypt",
        "kms:GenerateDataKey"
      ]
      resources = [local.access_key_rotation_secret_kms_key_id]
    }
  }
}

resource "aws_iam_role_policy" "access_key_rotation_lambda" {
  count = local.access_key_rotation_enabled && local.access_key_rotation_create_lambda ? 1 : 0

  name   = "${local.access_key_rotation_lambda_role_name}-policy"
  role   = aws_iam_role.access_key_rotation_lambda[0].id
  policy = data.aws_iam_policy_document.access_key_rotation_lambda[0].json
}

resource "aws_cloudwatch_log_group" "access_key_rotation_lambda" {
  count = local.access_key_rotation_enabled && local.access_key_rotation_create_lambda ? 1 : 0

  name              = "/aws/lambda/${local.access_key_rotation_function_name}"
  retention_in_days = local.access_key_rotation_log_retention_days
  tags              = local.all_tags
}

resource "aws_lambda_function" "access_key_rotation" {
  count = local.access_key_rotation_enabled && local.access_key_rotation_create_lambda ? 1 : 0

  function_name    = local.access_key_rotation_function_name
  description      = "Rotates IAM user access keys through AWS Secrets Manager rotation."
  filename         = data.archive_file.access_key_rotation_lambda[0].output_path
  source_code_hash = data.archive_file.access_key_rotation_lambda[0].output_base64sha256
  role             = aws_iam_role.access_key_rotation_lambda[0].arn
  handler          = "iam_access_key_rotation.handler"
  runtime          = "python3.11"
  timeout          = local.access_key_rotation_lambda_timeout
  memory_size      = local.access_key_rotation_lambda_memory_size
  layers           = local.access_key_rotation_lambda_layer_arns
  tags             = local.all_tags

  environment {
    variables = {
      ROTATION_CONFIG_SECRET_ID = aws_secretsmanager_secret.access_key_rotation_config[0].arn
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.access_key_rotation_lambda,
    aws_iam_role_policy.access_key_rotation_lambda
  ]

  lifecycle {
    precondition {
      condition     = !local.access_key_rotation_pgp_enabled || length(local.access_key_rotation_lambda_layer_arns) > 0
      error_message = "PGP is configured for at least one rotated user. Provide access_key_rotation.lambda_layer_arns with a layer containing the pgpy package."
    }
  }
}

resource "aws_lambda_permission" "access_key_rotation" {
  for_each = local.access_key_rotation_enabled ? local.access_key_rotation_user_config : {}

  statement_id   = "AllowSecretsManager${substr(sha1(each.key), 0, 16)}"
  action         = "lambda:InvokeFunction"
  function_name  = local.access_key_rotation_effective_lambda_arn
  principal      = "secretsmanager.amazonaws.com"
  source_account = data.aws_caller_identity.current.account_id
  source_arn     = local.access_key_rotation_secret_resource_arn_map[each.key]
}

resource "aws_secretsmanager_secret_rotation" "access_key_rotation" {
  for_each = local.access_key_rotation_enabled ? local.access_key_rotation_user_config : {}

  secret_id           = local.access_key_rotation_secret_id_map[each.key]
  rotation_lambda_arn = local.access_key_rotation_effective_lambda_arn
  rotate_immediately  = local.access_key_rotation_rotate_immediately

  rotation_rules {
    automatically_after_days = local.access_key_rotation_schedule_expression == null ? local.access_key_rotation_automatically_after_days : null
    schedule_expression      = local.access_key_rotation_schedule_expression
    duration                 = local.access_key_rotation_schedule_duration
  }

  depends_on = [aws_lambda_permission.access_key_rotation]

  lifecycle {
    precondition {
      condition     = local.access_key_rotation_create_lambda || local.access_key_rotation_lambda_arn != null
      error_message = "When access_key_rotation.create_lambda is false, access_key_rotation.lambda_arn is required."
    }
  }
}
