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

output "iam_access_keys" {
  value = [
    for key in aws_iam_access_key.this : {
      id                = key.id
      secret            = key.secret
      smtp_password     = key.ses_smtp_password_v4
      user_name         = key.user
      create_date       = key.create_date
      status            = key.status
      enc_secret        = key.encrypted_secret
      enc_smtp_password = key.encrypted_ses_smtp_password_v4
    }
  ]
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