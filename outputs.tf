##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

output "users" {
  description = "IAM user metadata created by this module. Secret values are not included."
  value = [
    for user in aws_iam_user.this : {
      name      = user.name
      arn       = user.arn
      path      = user.path
      unique_id = user.unique_id
    }
  ]
}

output "users_by_name" {
  description = "IAM user metadata keyed by IAM user name for downstream module lookups. Secret values are not included."
  value = {
    for user in aws_iam_user.this : user.name => {
      name      = user.name
      arn       = user.arn
      path      = user.path
      unique_id = user.unique_id
    }
  }
}

output "groups" {
  description = "IAM group metadata for managed and referenced groups. Secret values are not included."
  value = concat([
    for group in aws_iam_group.named : {
      name      = group.name
      arn       = group.arn
      path      = group.path
      unique_id = group.unique_id
      existing  = false
      kind      = "named"
    }
    ], [
    for group in data.aws_iam_group.named : {
      name      = group.group_name
      arn       = group.arn
      path      = group.path
      unique_id = try(group.unique_id, group.group_id, group.id)
      existing  = true
      kind      = "named"
    }
    ], [
    for group in aws_iam_group.prefixed : {
      name      = group.name
      arn       = group.arn
      path      = group.path
      unique_id = group.unique_id
      existing  = false
      kind      = "prefixed"
    }
  ])
}

output "groups_by_name" {
  description = "IAM group metadata keyed by IAM group name for downstream module lookups. Secret values are not included."
  value = merge({
    for group in aws_iam_group.named : group.name => {
      name      = group.name
      arn       = group.arn
      path      = group.path
      unique_id = group.unique_id
      existing  = false
      kind      = "named"
    }
    }, {
    for group in data.aws_iam_group.named : group.group_name => {
      name      = group.group_name
      arn       = group.arn
      path      = group.path
      unique_id = try(group.unique_id, group.group_id, group.id)
      existing  = true
      kind      = "named"
    }
    }, {
    for group in aws_iam_group.prefixed : group.name => {
      name      = group.name
      arn       = group.arn
      path      = group.path
      unique_id = group.unique_id
      existing  = false
      kind      = "prefixed"
    }
  })
}

output "user_group_memberships" {
  description = "Resolved IAM group memberships keyed by IAM user name."
  value = {
    for user_name, membership in aws_iam_user_group_membership.this : user_name => {
      user   = membership.user
      groups = membership.groups
    }
  }
}

output "iam_access_keys" {
  description = "Compatibility output for IAM access key metadata only; secret access key values are not included. Marked sensitive to preserve the historical output contract."
  value = [
    for key_name, key in aws_iam_access_key.this : {
      key_name    = key_name
      id          = key.id
      user_name   = key.user
      create_date = key.create_date
      status      = key.status
    }
  ]
  sensitive = true
}

output "iam_access_key_metadata" {
  description = "Non-secret IAM access key metadata keyed by logical key name. Secret access key values are not included."
  value = {
    for key_name, key in aws_iam_access_key.this : key_name => {
      key_name    = key_name
      id          = key.id
      user_name   = key.user
      create_date = key.create_date
      status      = key.status
    }
  }
}

output "policies" {
  description = "IAM managed policy metadata created by this module."
  value = concat([
    for policy in aws_iam_policy.named : {
      name      = policy.name
      arn       = policy.arn
      id        = policy.id
      policy_id = policy.policy_id
      path      = policy.path
      kind      = "named"
    }
    ], [
    for policy in aws_iam_policy.prefixed : {
      name      = policy.name
      arn       = policy.arn
      id        = policy.id
      policy_id = policy.policy_id
      path      = policy.path
      kind      = "prefixed"
    }
  ])
}

output "policies_by_name" {
  description = "IAM managed policy metadata keyed by policy name for downstream module lookups."
  value = merge({
    for policy in aws_iam_policy.named : policy.name => {
      name      = policy.name
      arn       = policy.arn
      id        = policy.id
      policy_id = policy.policy_id
      path      = policy.path
      kind      = "named"
    }
    }, {
    for policy in aws_iam_policy.prefixed : policy.name => {
      name      = policy.name
      arn       = policy.arn
      id        = policy.id
      policy_id = policy.policy_id
      path      = policy.path
      kind      = "prefixed"
    }
  })
}

output "group_policy_attachments" {
  description = "Resolved IAM group managed-policy attachments, including external policy ARNs and module policy references."
  value = merge({
    for key, attachment in aws_iam_group_policy_attachment.named : key => {
      group      = attachment.group
      policy_arn = attachment.policy_arn
      id         = attachment.id
      kind       = "named_external"
    }
    }, {
    for key, attachment in aws_iam_group_policy_attachment.prefixed : key => {
      group      = attachment.group
      policy_arn = attachment.policy_arn
      id         = attachment.id
      kind       = "prefixed_external"
    }
    }, {
    for key, attachment in aws_iam_group_policy_attachment.named_refs : key => {
      group      = attachment.group
      policy_arn = attachment.policy_arn
      id         = attachment.id
      kind       = "named_module_ref"
    }
    }, {
    for key, attachment in aws_iam_group_policy_attachment.prefixed_refs : key => {
      group      = attachment.group
      policy_arn = attachment.policy_arn
      id         = attachment.id
      kind       = "prefixed_module_ref"
    }
  })
}

output "group_inline_policies" {
  description = "Resolved IAM group inline policies keyed by module logical attachment name."
  value = merge({
    for key, policy in aws_iam_group_policy.named_inline : key => {
      name  = policy.name
      group = policy.group
      id    = policy.id
      kind  = "named_inline"
    }
    }, {
    for key, policy in aws_iam_group_policy.prefixed_inline : key => {
      name  = policy.name
      group = policy.group
      id    = policy.id
      kind  = "prefixed_inline"
    }
  })
}

output "secrets_manager_secret_refs" {
  description = "Secrets Manager secret references created by this module for console credentials and Terraform-managed access keys. Secret values are not included."
  value = {
    console_passwords = {
      for user_name, secret in aws_secretsmanager_secret.user_login : user_name => {
        name = secret.name
        arn  = secret.arn
      }
    }
    access_keys = {
      for key_name, secret in aws_secretsmanager_secret.user_secret : key_name => {
        name      = secret.name
        arn       = secret.arn
        user_name = local.user_access_keys[key_name].user_name
      }
    }
  }
}

output "access_key_rotation" {
  description = "Non-secret metadata for the optional AWS Secrets Manager IAM access key rotation control plane. Secret values are not included."
  value = {
    enabled                     = local.access_key_rotation_enabled
    rotation_provider           = "aws_secretsmanager_secret_rotation"
    create_lambda               = local.access_key_rotation_create_lambda
    rotate_after_days           = local.access_key_rotation_rotate_after_days
    automatically_after_days    = local.access_key_rotation_automatically_after_days
    schedule_expression         = local.access_key_rotation_schedule_expression
    schedule_duration           = local.access_key_rotation_schedule_duration
    rotate_immediately          = local.access_key_rotation_rotate_immediately
    grace_period_days           = local.access_key_rotation_grace_period_days
    inactive_key_retention_days = local.access_key_rotation_inactive_key_retention_days
    delete_inactive_keys        = local.access_key_rotation_delete_inactive_keys
    requested_user_names        = local.access_key_rotation_requested_user_names
    target_user_names           = local.access_key_rotation_target_user_names
    configured_user_names       = local.access_key_rotation_user_config_target_names
    ignored_user_names          = local.access_key_rotation_ignored_user_names
    user_opt_out_names          = local.access_key_rotation_user_opt_out_names
    selected_groups             = local.access_key_rotation_group_selectors
    excluded_users              = local.access_key_rotation_excluded_users
    pgp_enabled_user_names      = [for user_name, cfg in local.access_key_rotation_user_config : user_name if cfg.pgp_enabled]
    secret_destination_type     = "secretsmanager"
    secret_prefix               = local.access_key_rotation_secret_prefix
    secret_ids                  = local.access_key_rotation_secret_id_map
    secret_resource_arns        = local.access_key_rotation_secret_resource_arn_map
    rotation_lambda_arn         = local.access_key_rotation_effective_lambda_arn
    lambda_function_name        = try(aws_lambda_function.access_key_rotation[0].function_name, null)
    lambda_function_arn         = try(aws_lambda_function.access_key_rotation[0].arn, null)
    lambda_role_arn             = try(aws_iam_role.access_key_rotation_lambda[0].arn, null)
    lambda_log_group_name       = try(aws_cloudwatch_log_group.access_key_rotation_lambda[0].name, null)
    config_secret_arn           = try(aws_secretsmanager_secret.access_key_rotation_config[0].arn, null)
    rotation_ids                = { for user_name, rotation in aws_secretsmanager_secret_rotation.access_key_rotation : user_name => rotation.id }
    runbook_hints = [
      "Enable access_key_rotation only for module-managed IAM users that should be rotated operationally.",
      "Rotation is configured with AWS Secrets Manager secret rotation; Secrets Manager invokes the rotation Lambda on the configured schedule.",
      "Do not consume secret values from Terraform outputs; replacement secrets are written directly to Secrets Manager by the rotation Lambda.",
      "aws_secretsmanager_secret_rotation is the resource that owns the Secrets Manager rotation schedule and Lambda association for each configured secret.",
      "For rotating users, Terraform-managed users[*].access_keys are intentionally skipped so aws_iam_access_key is not recreated after the rotation Lambda changes the IAM key set.",
      "When users is non-empty it overrides group-derived selection; exclude_users and user-level access_key_rotation_enabled=false remove users from either scope.",
      "If create_secrets is false, provide access_key_rotation.secret_arns for every selected user.",
      "If any selected user has default_pgp_key or pgp_key configured and create_lambda is true, provide access_key_rotation.lambda_layer_arns with a layer containing pgpy."
    ]
  }
}
