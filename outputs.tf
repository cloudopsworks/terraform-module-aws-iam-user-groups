##
# (c) 2021-2025
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
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

output "iam_access_keys" {
  value = [
    for key in aws_iam_access_key.this : {
      id          = key.id
      user_name   = key.user
      create_date = key.create_date
      status      = key.status
    }
  ]
  sensitive = true
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