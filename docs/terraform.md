## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | ~> 2.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.35 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | 2.8.0 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.51.0 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | 4.3.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_tags"></a> [tags](#module\_tags) | cloudopsworks/tags/local | 1.0.9 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.access_key_rotation_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_access_key.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_access_key) | resource |
| [aws_iam_group.named](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_group) | resource |
| [aws_iam_group.prefixed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_group) | resource |
| [aws_iam_group_policy.named_inline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_group_policy) | resource |
| [aws_iam_group_policy.prefixed_inline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_group_policy) | resource |
| [aws_iam_group_policy_attachment.named](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_group_policy_attachment) | resource |
| [aws_iam_group_policy_attachment.named_refs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_group_policy_attachment) | resource |
| [aws_iam_group_policy_attachment.prefixed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_group_policy_attachment) | resource |
| [aws_iam_group_policy_attachment.prefixed_refs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_group_policy_attachment) | resource |
| [aws_iam_policy.named](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.prefixed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.access_key_rotation_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.access_key_rotation_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_service_specific_credential.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_service_specific_credential) | resource |
| [aws_iam_user.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user) | resource |
| [aws_iam_user_group_membership.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user_group_membership) | resource |
| [aws_iam_user_login_profile.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user_login_profile) | resource |
| [aws_iam_user_ssh_key.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user_ssh_key) | resource |
| [aws_lambda_function.access_key_rotation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_permission.access_key_rotation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_secretsmanager_secret.access_key_rotation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret.access_key_rotation_config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret.user_login](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret.user_secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_rotation.access_key_rotation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_rotation) | resource |
| [aws_secretsmanager_secret_version.access_key_rotation_config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_secretsmanager_secret_version.user_login](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_secretsmanager_secret_version.user_secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [tls_private_key.this](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [archive_file.access_key_rotation_lambda](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_group.named](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_group) | data source |
| [aws_iam_policy.named](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy) | data source |
| [aws_iam_policy.prefixed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy) | data source |
| [aws_iam_policy_document.access_key_rotation_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.access_key_rotation_lambda_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.named](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.named_inline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.prefixed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.prefixed_inline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_secretsmanager_secret_version.pgp_public_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version) | data source |
| [aws_secretsmanager_secret_version.user_pgp_public_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_key_rotation"></a> [access\_key\_rotation](#input\_access\_key\_rotation) | Optional AWS Secrets Manager IAM access key rotation control plane. Disabled by default. See comments above for full schema. | `any` | `{}` | no |
| <a name="input_default_pgp_key"></a> [default\_pgp\_key](#input\_default\_pgp\_key) | Default PGP key for encrypting secrets. Accepts raw armored PGP or "\_aws:<secret\_id>" to load it from AWS Secrets Manager. | `string` | `""` | no |
| <a name="input_extra_tags"></a> [extra\_tags](#input\_extra\_tags) | Extra tags to add to the resources | `map(string)` | `{}` | no |
| <a name="input_groups"></a> [groups](#input\_groups) | List of IAM groups (named or prefixed). See comments above for full schema. | `any` | `[]` | no |
| <a name="input_is_hub"></a> [is\_hub](#input\_is\_hub) | Is this a hub or spoke configuration? | `bool` | `false` | no |
| <a name="input_org"></a> [org](#input\_org) | Organization details | <pre>object({<br/>    organization_name = string<br/>    organization_unit = string<br/>    environment_type  = string<br/>    environment_name  = string<br/>  })</pre> | n/a | yes |
| <a name="input_policies"></a> [policies](#input\_policies) | List of IAM policies (named or prefixed). See comments above for full schema and example. | `any` | `[]` | no |
| <a name="input_secrets_manager_store"></a> [secrets\_manager\_store](#input\_secrets\_manager\_store) | Save secrets to the AWS Secrets Manager Store | `bool` | `false` | no |
| <a name="input_spoke_def"></a> [spoke\_def](#input\_spoke\_def) | Spoke ID Number, must be a 3 digit number | `string` | `"001"` | no |
| <a name="input_users"></a> [users](#input\_users) | List of IAM users (see comments above for full schema). | `any` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_access_key_rotation"></a> [access\_key\_rotation](#output\_access\_key\_rotation) | Non-secret metadata for the optional AWS Secrets Manager IAM access key rotation control plane. Secret values are not included. |
| <a name="output_group_inline_policies"></a> [group\_inline\_policies](#output\_group\_inline\_policies) | Resolved IAM group inline policies keyed by module logical attachment name. |
| <a name="output_group_policy_attachments"></a> [group\_policy\_attachments](#output\_group\_policy\_attachments) | Resolved IAM group managed-policy attachments, including external policy ARNs and module policy references. |
| <a name="output_groups"></a> [groups](#output\_groups) | IAM group metadata for managed and referenced groups. Secret values are not included. |
| <a name="output_groups_by_name"></a> [groups\_by\_name](#output\_groups\_by\_name) | IAM group metadata keyed by IAM group name for downstream module lookups. Secret values are not included. |
| <a name="output_iam_access_key_metadata"></a> [iam\_access\_key\_metadata](#output\_iam\_access\_key\_metadata) | Non-secret IAM access key metadata keyed by logical key name. Secret access key values are not included. |
| <a name="output_iam_access_keys"></a> [iam\_access\_keys](#output\_iam\_access\_keys) | Compatibility output for IAM access key metadata only; secret access key values are not included. Marked sensitive to preserve the historical output contract. |
| <a name="output_policies"></a> [policies](#output\_policies) | IAM managed policy metadata created by this module. |
| <a name="output_policies_by_name"></a> [policies\_by\_name](#output\_policies\_by\_name) | IAM managed policy metadata keyed by policy name for downstream module lookups. |
| <a name="output_secrets_manager_secret_refs"></a> [secrets\_manager\_secret\_refs](#output\_secrets\_manager\_secret\_refs) | Secrets Manager secret references created by this module for console credentials and Terraform-managed access keys. Secret values are not included. |
| <a name="output_user_group_memberships"></a> [user\_group\_memberships](#output\_user\_group\_memberships) | Resolved IAM group memberships keyed by IAM user name. |
| <a name="output_users"></a> [users](#output\_users) | IAM user metadata created by this module. Secret values are not included. |
| <a name="output_users_by_name"></a> [users\_by\_name](#output\_users\_by\_name) | IAM user metadata keyed by IAM user name for downstream module lookups. Secret values are not included. |
