##
# (c) 2021-2025
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
# secrets_manager_store
#   When true, the module saves generated secrets into AWS Secrets Manager under
#   the path: 
#     /<org_unit>/<environment_name>/<environment_type>/
#   The following secrets are stored when applicable:
#   - IAM user console passwords (either clear or PGP-encrypted string returned
#     by aws_iam_user_login_profile)
#   - IAM user access keys metadata and secrets, including:
#       access_key_id, access_key_secret|encrypted_secret, ses_smtp_password,
#       and whether PGP encryption was used (pgp: yes/no)
#
variable "secrets_manager_store" {
  description = "Save secrets to the AWS Secrets Manager Store"
  type        = bool
  default     = false
}

# default_pgp_key
#   Default PGP key used to encrypt sensitive values (console passwords and
#   access keys) when no user-level pgp_key is provided. Two formats supported:
#   - Raw PGP public key (armored text)
#   - "_aws:<secret_id>" to load the PGP public key from AWS Secrets Manager
#     Secret value. Example: "_aws:prod/shared/pgp/public".
#
variable "default_pgp_key" {
  description = "Default PGP key for encrypting secrets. Accepts raw armored PGP or \"_aws:<secret_id>\" to load it from AWS Secrets Manager."
  type        = string
  default     = ""
}

# ----------------------------------------------------------------------------
# users
# ----------------------------------------------------------------------------
# Structure: list(object) — kept as 'any' for flexibility; documented shape:
#
# users = [
#   {
#     name  = string                      # REQUIRED. IAM user name
#     path  = optional(string)            # Optional IAM path (e.g., "/service/")
#
#     # Optional override for PGP. If omitted, module-level default_pgp_key is used
#     pgp_key = optional(string)          # raw armored PGP or "_aws:<secret_id>"
#
#     # Group memberships for this user. IMPORTANT:
#     #  - For named groups, use the exact group.name provided in var.groups
#     #  - For prefixed groups, use the group.name_prefix (the module will expand
#     #    it to "<name_prefix>-<system_name>")
#     groups = optional(list(string))
#
#     # Access keys to create for this user
#     access_keys = optional(list(object({
#       name   = string                   # Logical name for the key (used internally)
#       status = optional(string)         # Defaults to "Active". Allowed: "Active"|"Inactive"
#     })))
#
#     # AWS Console access configuration
#     console_access = optional(object({
#       enabled                 = bool   # When true, create login profile (password)
#       password_length         = optional(number) # Default: 20
#       password_reset_required = optional(bool)   # Default: true
#     }))
#
#     # AWS CodeCommit credentials
#     code_commit = optional(object({
#       http_credentials = optional(bool)  # When true, create service-specific HTTP creds
#       ssh_credentials  = optional(bool)  # When true, generate RSA key pair and upload SSH public key
#     }))
#   }
# ]
#
# Notes:
# - PGP encryption precedence for access keys: user.pgp_key (if set) else default_pgp_key.
# - If secrets_manager_store is true, generated passwords/keys are stored under the
#   Secrets Manager path built from var.org.
# - outputs.tf exposes created users and access keys metadata (sensitive).
#
variable "users" {
  description = "List of IAM users (see comments above for full schema)."
  type        = any
  default     = []
}

# ----------------------------------------------------------------------------
# groups
# ----------------------------------------------------------------------------
# Two mutually exclusive forms per entry:
# 1) Named group (explicit name)
#    {
#      name               = string                 # REQUIRED
#      path               = optional(string)
#      existing           = optional(bool)         # If true, reference existing IAM group by name
#
#      # Attach existing AWS managed policies by ARN
#      policy_attachments = optional(list(string)) # e.g., ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
#
#      # Attach policies created by this module via var.policies.
#      # Provide the policy identifier key as defined in var.policies (name or name_prefix)
#      policy_refs        = optional(list(string))
#
#      # Inline policies to create and attach to this group
#      inline_policies = optional(list(object({
#        name       = string
#        statements = list(object({
#          sid       = optional(string)
#          effect    = string                 # "Allow" | "Deny"
#          actions   = list(string)
#          resources = list(string)
#          conditions = optional(list(object({
#            test     = string
#            variable = string
#            values   = list(string)
#          })))
#        }))
#      })))
#    }
#
# 2) Prefixed group (name generated as "<name_prefix>-<system_name>")
#    {
#      name_prefix        = string                 # REQUIRED
#      path               = optional(string)
#
#      policy_attachments = optional(list(string))
#      policy_refs        = optional(list(string))
#      inline_policies    = optional(list(object({ ... })) ) # same as above
#    }
#
# Note: In var.users[*].groups you must reference either the explicit group.name (for
#       named groups) or the group.name_prefix (for prefixed groups).
#
variable "groups" {
  description = "List of IAM groups (named or prefixed). See comments above for full schema."
  type        = any
  default     = []
}

# ----------------------------------------------------------------------------
# policies
# ----------------------------------------------------------------------------
# Policies created by the module (referenced by groups via policy_refs).
# Two forms supported per entry:
# 1) Named policy
#    {
#      name       = string                 # REQUIRED
#      statements = list(object({          # Same document structure used for inline policies
#        sid       = optional(string)
#        effect    = string                # "Allow" | "Deny"
#        actions   = list(string)
#        resources = list(string)
#        conditions = optional(list(object({
#          test     = string
#          variable = string
#          values   = list(string)
#        })))
#      }))
#    }
#
# 2) Prefixed policy (name generated as "<name_prefix>-<system_name>")
#    {
#      name_prefix = string               # REQUIRED
#      statements  = list(object({ ... }))
#    }
#
# You can then reference these policies in groups[*].policy_refs by their identifier
# (i.e., the "name" for named policies or the "name_prefix" for prefixed policies).
#
# Example (full):
#
# policies = [
#   {
#     name = "ReadOnlyPolicy"
#     statements = [{
#       effect    = "Allow"
#       actions   = ["ec2:Describe*", "s3:List*"]
#       resources = ["*"]
#     }]
#   },
#   {
#     name_prefix = "billing"
#     statements = [{
#       effect    = "Allow"
#       actions   = ["aws-portal:ViewBilling"]
#       resources = ["*"]
#     }]
#   }
# ]
#
variable "policies" {
  description = "List of IAM policies (named or prefixed). See comments above for full schema and example."
  type        = any
  default     = []
}