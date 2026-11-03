##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

locals {
  # Every managed-policy attachment (external ARNs and module policies) as {group, policy_arn}.
  output_group_policy_attachments = concat(
    values(aws_iam_group_policy_attachment.named),
    values(aws_iam_group_policy_attachment.prefixed),
    values(aws_iam_group_policy_attachment.named_refs),
    values(aws_iam_group_policy_attachment.prefixed_refs),
  )
  output_group_inline_policies = concat(
    values(aws_iam_group_policy.named_inline),
    values(aws_iam_group_policy.prefixed_inline),
  )
  # Created and referenced (existing) groups, keyed by the real IAM group name.
  output_groups = merge(
    { for g in aws_iam_group.named : g.name => { arn = g.arn, path = g.path, unique_id = g.unique_id, existing = false } },
    { for g in aws_iam_group.prefixed : g.name => { arn = g.arn, path = g.path, unique_id = g.unique_id, existing = false } },
    { for g in data.aws_iam_group.named : g.group_name => { arn = g.arn, path = g.path, unique_id = g.group_id, existing = true } },
  )
}

output "users" {
  description = "IAM users keyed by user name, with their group memberships and the Secrets Manager secret ARN holding the console password (null when not stored). Secret values are not included."
  value = {
    for name, user in aws_iam_user.this : name => {
      name                        = user.name
      arn                         = user.arn
      path                        = user.path
      unique_id                   = user.unique_id
      groups                      = sort(tolist(aws_iam_user_group_membership.this[name].groups))
      console_password_secret_arn = try(aws_secretsmanager_secret.user_login[name].arn, null)
    }
  }
}

output "groups" {
  description = "IAM groups (created or referenced with existing = true) keyed by IAM group name, with their attached managed policy ARNs and inline policy names."
  value = {
    for name, group in local.output_groups : name => merge(group, {
      name            = name
      policy_arns     = sort(distinct([for a in local.output_group_policy_attachments : a.policy_arn if a.group == name]))
      inline_policies = sort([for p in local.output_group_inline_policies : p.name if p.group == name])
    })
  }
}

output "policies" {
  description = "IAM managed policies created by this module, keyed by policy name."
  value = {
    for policy in concat(values(aws_iam_policy.named), values(aws_iam_policy.prefixed)) : policy.name => {
      name      = policy.name
      arn       = policy.arn
      path      = policy.path
      policy_id = policy.policy_id
    }
  }
}

output "access_keys" {
  description = "Terraform-managed IAM access keys keyed by \"<user>-<key name>\": key ID, status, duration and expiry (the next Terraform run after expires_at replaces the key), and the Secrets Manager secret ARN holding the key (null when not stored). Secret values are not included."
  value = {
    for key_name, key in aws_iam_access_key.this : key_name => {
      user_name     = key.user
      key_name      = local.user_access_keys[key_name].key_name
      id            = key.id
      status        = key.status
      create_date   = key.create_date
      duration_days = local.user_access_keys[key_name].duration_days
      expires_at    = time_rotating.access_key[key_name].rotation_rfc3339
      secret_arn    = try(aws_secretsmanager_secret.user_secret[key_name].arn, null)
    }
  }
}
