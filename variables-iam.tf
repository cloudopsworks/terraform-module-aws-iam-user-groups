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

# ----------------------------------------------------------------------------
# users
# ----------------------------------------------------------------------------
# users:
#   - name: "username" # (Required) IAM user name
#     path: "/" # (Optional) IAM path (e.g., "/service/"). Default: "/"
#     pgp_key: "armored_pgp_key" # (Optional) User-specific PGP key for encrypting secrets. Accepts raw armored PGP or "_aws:<secret_id>" to load it from AWS Secrets Manager. Default: ""
#     groups: ["group1"] # (Optional) Group memberships for this user. For named groups, use the exact group.name. For prefixed groups, use the group.name_prefix. Default: []
#     access_keys: # (Optional) Access keys to create for this user. Default: []
#       - name: "key1" # (Required) Logical name for the key (used internally)
#         status: "Active" # (Optional) Status of the key. Possible values: "Active", "Inactive". Default: "Active"
#         duration_days: 90 # (Optional) Maximum key lifetime in days. Once expired, the next Terraform run replaces the key (and its Secrets Manager secret when secrets_manager_store is true). Whole number between 15 and 365. Default: 90
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

  validation {
    condition = alltrue(flatten([
      for user in var.users : [
        for key in try(user.access_keys, []) :
        try(key.duration_days, 90) >= 15 && try(key.duration_days, 90) <= 365 && floor(try(key.duration_days, 90)) == try(key.duration_days, 90)
      ]
    ]))
    error_message = "users[*].access_keys[*].duration_days must be a whole number of days between 15 and 365."
  }
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
