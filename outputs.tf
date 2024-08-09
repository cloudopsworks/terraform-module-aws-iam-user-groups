##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

output "users" {
  value = [
    for user in aws_iam_user.this : {
      name = user.name
      arn  = user.arn
    }
  ]
}

output "groups" {
  value = concat([
    for group in aws_iam_group.named : {
      name = group.name
      arn  = group.arn
    }
    ],
    [
      for group in aws_iam_group.prefixed : {
        name = group.name
        arn  = group.arn
      }
  ])
}

output "policies" {
  value = concat([
    for policy in aws_iam_policy.named : {
      name = policy.name
      arn  = policy.arn
    }
    ],
    [
      for policy in aws_iam_policy.prefixed : {
        name = policy.name
        arn  = policy.arn
      }
  ])
}