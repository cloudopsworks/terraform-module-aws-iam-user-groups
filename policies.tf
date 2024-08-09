##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

locals {
  named_policy_map = {
    for policy in var.policies : policy.name => policy
    if try(policy.name, "") != "" && try(policy.name_prefix, "") == ""
  }
  prefixed_policy_map = {
    for policy in var.policies : policy.name => policy
    if try(policy.name, "") == "" && try(policy.name_prefix, "") != ""
  }
}

# Inline policies
data "aws_iam_policy_document" "named" {
  for_each = local.named_policy_map
  version  = "2012-10-17"
  dynamic "statement" {
    for_each = each.value.statements
    content {
      sid       = try(statement.value.sid, null)
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = statement.value.resources
      dynamic "condition" {
        for_each = try(statement.value.conditions, [])
        content {
          test     = condition.value.test
          values   = condition.value.values
          variable = condition.value.variable
        }
      }
    }
  }
}

resource "aws_iam_policy" "named" {
  for_each = local.named_policy_map
  name     = each.value.name
  policy   = data.aws_iam_policy_document.named[each.key].json
  tags     = local.all_tags
}

# Inline policies
data "aws_iam_policy_document" "prefixed" {
  for_each = local.prefixed_policy_map
  version  = "2012-10-17"
  dynamic "statement" {
    for_each = each.value.statements
    content {
      sid       = try(statement.value.sid, null)
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = statement.value.resources
      dynamic "condition" {
        for_each = try(statement.value.conditions, [])
        content {
          test     = condition.value.test
          values   = condition.value.values
          variable = condition.value.variable
        }
      }
    }
  }
}

resource "aws_iam_policy" "prefixed" {
  for_each = local.prefixed_policy_map
  name     = "${each.value.name_prefix}-${local.system_name}"
  policy   = data.aws_iam_policy_document.prefixed[each.key].json
  tags     = local.all_tags
}