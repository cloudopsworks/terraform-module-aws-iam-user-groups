##
# (c) 2021-2025
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
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
  secret_string = aws_iam_user_login_profile.this[each.key].password != "" ? aws_iam_user_login_profile.this[each.key].password : aws_iam_user_login_profile.this[each.key].encrypted_password
}

resource "aws_secretsmanager_secret" "user_secret" {
  for_each = {
    for k, v in local.user_access_keys : k => v
    if var.secrets_manager_store
  }
  name = "${local.secret_store_path}/iam-user/${each.value.user_name}"
  tags = local.all_tags
}

resource "aws_secretsmanager_secret_version" "user_secret" {
  for_each = {
    for k, v in local.user_access_keys : k => v
    if var.secrets_manager_store
  }
  secret_id = aws_secretsmanager_secret.user_secret[each.key].id
  secret_string = jsonencode({
    access_key_id     = aws_iam_access_key.this[each.key].id
    access_key_secret = aws_iam_access_key.this[each.key].secret != "" ? aws_iam_access_key.this[each.key].secret : aws_iam_access_key.this[each.key].encrypted_secret
    ses_smtp_password = aws_iam_access_key.this[each.key].ses_smtp_password_v4
    pgp               = aws_iam_access_key.this[each.key].secret != "" ? "no" : "yes"
  })
}

