##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#
locals {
  # Maximum lifetime of a Terraform-managed access key before the next run replaces it.
  access_key_default_duration_days = 90

  users_map = {
    for user in var.users : user.name => user
  }

  default_pgp_key = startswith(
    var.default_pgp_key,
    "_aws:"
  ) ? data.aws_secretsmanager_secret_version.pgp_public_key[0].secret_string : var.default_pgp_key

  user_access_keys = merge([
    for user in var.users : {
      for key in try(user.access_keys, []) : "${user.name}-${key.name}" => {
        user_name     = user.name
        key_name      = key.name
        status        = try(key.status, "Active")
        duration_days = try(key.duration_days, local.access_key_default_duration_days)
        pgp_key       = try(local.user_pgp_key_map[user.name], "") != "" ? local.user_pgp_key_map[user.name] : null
      }
    }
  ]...)

  user_pgp_secret_ids = {
    for user in var.users : user.name => replace(user.pgp_key, "_aws:", "")
    if try(user.pgp_key, "") != "" && startswith(try(user.pgp_key, ""), "_aws:")
  }
  user_pgp_key_map = {
    for user in var.users : user.name => try(user.pgp_key, "") != "" ? (
      startswith(try(user.pgp_key, ""), "_aws:") ? try(data.aws_secretsmanager_secret_version.user_pgp_public_key[user.name].secret_string, "") : user.pgp_key
    ) : local.default_pgp_key
  }

  user_console_access = {
    for user in var.users : user.name => user
    if try(user.console_access.enabled, false)
  }
}

# PGP Key for Secrets Manager
data "aws_secretsmanager_secret_version" "pgp_public_key" {
  count     = var.default_pgp_key != "" && startswith(var.default_pgp_key, "_aws:") ? 1 : 0
  secret_id = replace(var.default_pgp_key, "_aws:", "")
}

# IAM USERS
data "aws_secretsmanager_secret_version" "user_pgp_public_key" {
  for_each  = local.user_pgp_secret_ids
  secret_id = each.value
}

resource "aws_iam_user" "this" {
  for_each = local.users_map
  name     = each.value.name
  path     = try(each.value.path, null)
  tags     = local.all_tags
}

# Expires after duration_days. Once expired, time_rotating is dropped on refresh and
# re-created on the next run, which changes time_static and replaces the access key.
resource "time_rotating" "access_key" {
  for_each      = local.user_access_keys
  rotation_days = each.value.duration_days
}

# time_rotating re-creation is a create action, which replace_triggered_by ignores;
# time_static turns it into a replacement so the access key rotation fires.
resource "time_static" "access_key" {
  for_each = local.user_access_keys
  rfc3339  = time_rotating.access_key[each.key].rfc3339
}

resource "aws_iam_access_key" "this" {
  for_each = local.user_access_keys
  user     = aws_iam_user.this[each.value.user_name].name
  status   = each.value.status
  pgp_key  = each.value.pgp_key

  lifecycle {
    replace_triggered_by = [time_static.access_key[each.key]]
  }
}

resource "aws_iam_user_login_profile" "this" {
  for_each                = local.user_console_access
  user                    = aws_iam_user.this[each.key].name
  pgp_key                 = try(local.user_pgp_key_map[each.key], "") != "" ? local.user_pgp_key_map[each.key] : null
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
