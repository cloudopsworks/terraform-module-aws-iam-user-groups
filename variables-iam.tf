##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

variable "secrets_manager_store" {
  description = "Save secrets to the AWS Secrets Manager Store"
  type        = bool
  default     = false
}

variable "users" {
  description = "List of IAM users"
  type        = any
  default     = []
}

variable "groups" {
  description = "List of IAM groups"
  type        = any
  default     = []
}

variable "policies" {
  description = "List of IAM policies"
  type        = any
  default     = []
}