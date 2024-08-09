##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#
locals {
  users_map = {
    for user in var.users : user.name => user
  }

  user_access_keys = merge([
    for user in var.users : {
      for key in try(user.access_keys, []) : "${user.name}-${key.name}" => {
        user_name = user.name
        key_name  = key.name
        status    = try(key.status, "Active")
        pgp_key   = try(user.pgp_key, null)
      }
    }
  ]...)

  user_console_access = {
    for user in var.users : user.name => user
    if try(user.console_access.enabled, false)
  }
}

# IAM USERS
resource "aws_iam_user" "this" {
  for_each = local.users_map
  name     = each.value.name
  path     = try(each.value.path, null)
  tags     = local.all_tags
}

resource "aws_iam_access_key" "this" {
  for_each = local.user_access_keys
  user     = aws_iam_user.this[each.value.user_name].name
  status   = each.value.status
  pgp_key  = each.value.pgp_key
}

resource "aws_iam_user_login_profile" "this" {
  for_each                = local.user_console_access
  user                    = aws_iam_user.this[each.key].name
  pgp_key                 = try(each.value.pgp_key, null)
  password_length         = try(each.value.console_access.password_length, 20)
  password_reset_required = try(each.value.console_access.password_reset_required, true)
}

resource "aws_iam_service_specific_credential" "this" {
  for_each = {
    for k, v in local.users_map : k => v
    if try(v.code_commit.http_credentials, false)
  }
  user_name    = aws_iam_user.this[each.key].name
  service_name = "codecommit.amazonaws.com"
}

resource "aws_iam_user_ssh_key" "this" {
  for_each = {
    for k, v in local.users_map : k => v
    if try(v.code_commit.ssh_credentials, false)
  }
  username   = aws_iam_user.this[each.key].name
  encoding   = "SSH"
  public_key = tls_private_key.this[each.key].public_key_openssh
}

resource "tls_private_key" "this" {
  for_each = {
    for k, v in local.users_map : k => v
    if try(v.code_commit.ssh_credentials, false)
  }
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_iam_user_group_membership" "this" {
  for_each = local.users_map
  user     = aws_iam_user.this[each.key].name
  groups = concat([
    for group in try(each.value.groups, []) : aws_iam_group.named[group].name
    if contains(keys(local.named_group_map), group)
    ], [
    for group in try(each.value.groups, []) : aws_iam_group.prefixed[group].name
    if contains(keys(local.group_map), group)
  ])
}

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

resource "aws_secretsmanager_secret" "access_keys" {
  for_each = {
    for k, v in local.user_access_keys : k => v
    if var.secrets_manager_store
  }
  name = "${local.secret_store_path}/iam-user/access-key/${each.value.user_name}/${each.value.key_name}"
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
  name = "${local.secret_store_path}/iam-user/ses-smtp-password/${each.value.user_name}/${each.value.key_name}"
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

