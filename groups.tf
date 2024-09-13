##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

locals {
  named_group_map = {
    for group in var.groups : group.name => group
    if try(group.name, "") != "" && try(group.name_prefix, "") == ""
  }

  # This is only for policy attachments
  named_policy_att = merge([
    for group in local.named_group_map : {
      for policy in try(group.policy_attachments, []) : "${group.name}-${policy}" => {
        group_name = group.name
        policy_arn = policy
      }
    }
  ]...)

  group_map = {
    for group in var.groups : group.name_prefix => group
    if try(group.name, "") == "" && try(group.name_prefix, "") != ""
  }
  prefix_policy_att = merge([
    for group in local.group_map : {
      for policy in try(group.policy_attachments, []) : "${group.name}-${policy}" => {
        group_name = group.name_prefix
        policy_arn = policy
      }
    }
  ]...)


  # this is only for policy refs, needs to check prefixed & named policies defined in the policy module
  named_policy_refs_att = merge([
    for group in local.named_group_map : {
      for policy in try(group.policy_refs, []) : "${group.name}-${policy}" => {
        group_name = group.name
        policy_ref = policy
      }
    }
  ]...)
  prefixed_policy_refs_att = merge([
    for group in local.group_map : {
      for policy in try(group.policy_refs, []) : "${group.name}-${policy}" => {
        group_prefix = group.name_prefix
        policy_ref   = policy
      }
    }
  ]...)
}

# named groups
resource "aws_iam_group" "named" {
  for_each = local.named_group_map
  name     = each.value.name
  path     = try(each.value.path, null)
}

data "aws_iam_policy" "named" {
  for_each = local.named_policy_att
  arn      = each.value.policy_arn
}

resource "aws_iam_group_policy_attachment" "named" {
  for_each   = local.named_policy_att
  group      = aws_iam_group.named[each.value.group_name].name
  policy_arn = data.aws_iam_policy.named[each.key].arn
}

# prefixed groups
resource "aws_iam_group" "prefixed" {
  for_each = local.group_map
  name     = "${each.value.name_prefix}-${local.system_name}"
  path     = try(each.value.path, null)
}

data "aws_iam_policy" "prefixed" {
  for_each = local.prefix_policy_att
  arn      = each.value.policy_arn
}

resource "aws_iam_group_policy_attachment" "prefixed" {
  for_each   = local.prefix_policy_att
  group      = aws_iam_group.named[each.value.group_name].name
  policy_arn = data.aws_iam_policy.prefixed[each.key].arn
}

resource "aws_iam_group_policy_attachment" "named_refs" {
  for_each   = local.named_policy_refs_att
  group      = aws_iam_group.named[each.value.group_name].name
  policy_arn = try(aws_iam_policy.named[each.value.policy_ref].arn, aws_iam_policy.prefixed[each.value.policy_ref].arn)
}

resource "aws_iam_group_policy_attachment" "prefixed_refs" {
  for_each   = local.prefixed_policy_refs_att
  group      = aws_iam_group.prefixed[each.value.group_prefix].name
  policy_arn = try(aws_iam_policy.named[each.value.policy_ref].arn, aws_iam_policy.prefixed[each.value.policy_ref].arn)
}
# TODO: Inline Policies