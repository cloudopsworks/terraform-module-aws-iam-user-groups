##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

# ----------------------------------------------------------------------------
# Global settings
# ----------------------------------------------------------------------------
#
# secrets_manager_store: false # (Optional) When true, the module saves generated secrets into AWS Secrets Manager under the path: /<org_unit>/<environment_name>/<environment_type>/. The following secrets are stored when applicable: IAM user console passwords, IAM user access keys metadata and secrets. Default: false
#
variable "secrets_manager_store" {
  description = "Save secrets to the AWS Secrets Manager Store"
  type        = bool
  default     = false
}

# default_pgp_key: "" # (Optional) Default PGP key used to encrypt sensitive values (console passwords and access keys) when no user-level pgp_key is provided. Two formats supported: Raw PGP public key (armored text) or "_aws:<secret_id>" to load the PGP public key from AWS Secrets Manager Secret value. Default: ""
#
variable "default_pgp_key" {
  description = "Default PGP key for encrypting secrets. Accepts raw armored PGP or \"_aws:<secret_id>\" to load it from AWS Secrets Manager."
  type        = string
  default     = ""
}


# access_key_rotation: # (Optional) Opt-in AWS Secrets Manager rotation control plane for IAM access keys. Default: disabled.
#   enabled: false # (Optional) When true, configure Secrets Manager rotation for selected module-managed users. Default: false
#   create_lambda: true # (Optional) When true, create the IAM access key rotation Lambda. Set false to use lambda_arn. Default: true
#   lambda_arn: null # (Optional) Existing rotation Lambda ARN to use when create_lambda is false. Default: null
#   lambda_layer_arns: [] # (Optional) Lambda layer ARNs. Required when PGP is active with the module-created Lambda; include a layer that provides pgpy. Default: []
#   lambda_timeout: 60 # (Optional) Module-created Lambda timeout in seconds. Default: 60
#   lambda_memory_size: 256 # (Optional) Module-created Lambda memory size in MB. Default: 256
#   lambda_function_name: "org-env-type-001-use1-iam-key-rotation" # (Optional) Module-created Lambda function name, truncated to 64 characters. Default: "<system_name_short>-iam-key-rotation"
#   lambda_role_name: "org-env-type-001-use1-iam-key-rotation-lambda" # (Optional) Module-created Lambda IAM role name, truncated to 64 characters. Default: "<system_name_short>-iam-key-rotation-lambda"
#   log_retention_days: 30 # (Optional) CloudWatch log retention for the module-created Lambda. Default: 30
#   automatically_after_days: 90 # (Optional) Secrets Manager automatic rotation interval when schedule_expression is not set. Default: rotate_after_days
#   schedule_expression: null # (Optional) Secrets Manager rotation schedule expression, for example "rate(30 days)" or a cron expression. Mutually exclusive with automatically_after_days. Default: null
#   schedule_duration: null # (Optional) Rotation window duration such as "2h" when schedule_expression is set. Default: null
#   rotate_immediately: false # (Optional) Whether to rotate immediately when rotation configuration is created. Default: false
#   rotate_after_days: 90 # (Optional) Lambda-side minimum age before it creates a replacement key. Default: 90
#   grace_period_days: 7 # (Optional) Days before older non-current keys are deactivated during a rotation invocation. Default: 7
#   inactive_key_retention_days: 30 # (Optional) Additional days before deleting inactive keys when delete_inactive_keys is true. Default: 30
#   delete_inactive_keys: false # (Optional) Delete inactive keys after grace_period_days + inactive_key_retention_days. Default: false
#   users: [] # (Optional) Explicit module-managed user allowlist. When provided, it overrides group-derived selection. Default: []
#   groups: [] # (Optional) Group references used in users[*].groups to derive selected users when users is empty. Default: []
#   exclude_users: [] # (Optional) Module-managed users removed from either all-users or group-derived scope. Default: []
#   create_secrets: true # (Optional) When true, create one Secrets Manager secret per selected user and enable rotation on it. Default: true
#   secret_prefix: "/org/env/type/iam-user/access-key-rotation" # (Optional) Prefix for module-created Secrets Manager secrets. Default: "/<org_unit>/<environment_name>/<environment_type>/iam-user/access-key-rotation"
#   secret_arns: {} # (Optional) Map of user name to existing Secrets Manager secret ARN/name when create_secrets is false or custom destinations are needed. Default: {}
#   secret_kms_key_id: null # (Optional) KMS key ID/ARN for module-created Secrets Manager secrets and rotation config. Default: null
#   secret_recovery_window_in_days: 30 # (Optional) Recovery window for module-created Secrets Manager secrets. Default: 30
#   config_secret_name: "/org/env/type/iam-user/access-key-rotation/_rotation-config" # (Optional) Name for the module-created Lambda configuration secret. Default: "<secret_prefix>/_rotation-config"
#
variable "access_key_rotation" {
  description = "Optional AWS Secrets Manager IAM access key rotation control plane. Disabled by default. See comments above for full schema."
  type        = any
  default     = {}
}

# ----------------------------------------------------------------------------
# users
# ----------------------------------------------------------------------------
# users:
#   - name: "username" # (Required) IAM user name
#     path: "/" # (Optional) IAM path (e.g., "/service/"). Default: "/"
#     pgp_key: "armored_pgp_key" # (Optional) User-specific PGP key for encrypting secrets. Accepts raw armored PGP or "_aws:<secret_id>" to load it from AWS Secrets Manager. Default: ""
#     access_key_rotation_enabled: true # (Optional) User-level opt-in/opt-out flag for the module-level access_key_rotation selection. Set false to exclude this user even when selected by users/groups/all-users scope. Default: true
#     groups: ["group1"] # (Optional) Group memberships for this user. For named groups, use the exact group.name. For prefixed groups, use the group.name_prefix. Default: []
#     access_keys: # (Optional) Access keys to create for this user. Default: []
#       - name: "key1" # (Required) Logical name for the key (used internally)
#         status: "Active" # (Optional) Status of the key. Possible values: "Active", "Inactive". Default: "Active"
#     console_access: # (Optional) AWS Console access configuration. Default: null
#       enabled: true # (Required) When true, create login profile (password)
#       password_length: 20 # (Optional) Default: 20
#       password_reset_required: true # (Optional) Default: true
#     code_commit: # (Optional) AWS CodeCommit credentials. Default: null
#       http_credentials: true # (Optional) When true, create service-specific HTTP creds. Default: false
#       ssh_credentials: true # (Optional) When true, generate RSA key pair and upload SSH public key. Default: false
#
variable "users" {
  description = "List of IAM users (see comments above for full schema)."
  type        = any
  default     = []
}

# ----------------------------------------------------------------------------
# groups
# ----------------------------------------------------------------------------
# groups:
#   - name: "groupname" # (Optional) Named group (explicit name). Either name or name_prefix is REQUIRED.
#     path: "/" # (Optional) IAM path. Default: "/"
#     existing: false # (Optional) If true, reference existing IAM group by name. Default: false
#     policy_attachments: ["arn:aws:iam::aws:policy/ReadOnlyAccess"] # (Optional) Attach existing AWS managed policies by ARN. Default: []
#     policy_refs: ["policy1"] # (Optional) Attach policies created by this module via var.policies. Provide the policy identifier key (name or name_prefix). Default: []
#     inline_policies: # (Optional) Inline policies to create and attach to this group. Default: []
#       - name: "inline-policy" # (Required) Name of the inline policy
#         statements: # (Required) List of policy statements
#           - sid: "sid1" # (Optional) Statement ID
#             effect: "Allow" # (Required) Effect of the statement. Possible values: "Allow", "Deny"
#             actions: ["s3:ListBucket"] # (Required) List of actions
#             resources: ["arn:aws:s3:::bucket-name"] # (Required) List of resources
#             conditions: # (Optional) List of conditions. Default: []
#               - test: "StringEquals" # (Required) Condition test
#                 variable: "aws:PrincipalTag/Department" # (Required) Condition variable
#                 values: ["IT"] # (Required) Condition values
#   - name_prefix: "group-prefix" # (Optional) Prefixed group (name generated as "<name_prefix>-<system_name>"). Either name or name_prefix is REQUIRED.
#     path: "/" # (Optional) IAM path. Default: "/"
#     policy_attachments: [] # (Optional) Default: []
#     policy_refs: [] # (Optional) Default: []
#     inline_policies: [] # (Optional) Default: []
#
variable "groups" {
  description = "List of IAM groups (named or prefixed). See comments above for full schema."
  type        = any
  default     = []
}

# ----------------------------------------------------------------------------
# policies
# ----------------------------------------------------------------------------
# policies:
#   - name: "policyname" # (Optional) Named policy. Either name or name_prefix is REQUIRED.
#     statements: # (Required) List of policy statements
#       - sid: "sid1" # (Optional) Statement ID
#         effect: "Allow" # (Required) Effect of the statement. Possible values: "Allow", "Deny"
#         actions: ["s3:ListBucket"] # (Required) List of actions
#         resources: ["arn:aws:s3:::bucket-name"] # (Required) List of resources
#         conditions: # (Optional) List of conditions. Default: []
#           - test: "StringEquals" # (Required) Condition test
#             variable: "aws:PrincipalTag/Department" # (Required) Condition variable
#             values: ["IT"] # (Required) Condition values
#   - name_prefix: "policy-prefix" # (Optional) Prefixed policy (name generated as "<name_prefix>-<system_name>"). Either name or name_prefix is REQUIRED.
#     statements: [] # (Required) List of policy statements
#
variable "policies" {
  description = "List of IAM policies (named or prefixed). See comments above for full schema and example."
  type        = any
  default     = []
}
