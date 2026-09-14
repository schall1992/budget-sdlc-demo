# One module, three deployment targets. Each workspace supplies its own
# envs/<target>.tfvars; every variable below defaults to "off" so a target
# only opts into what it owns.

variable "create_shared" {
  type        = bool
  default     = false
  description = <<-EOT
    Create the account-wide objects that no single environment owns: the
    warehouse and the CI service user. True only for the shared target —
    creating these twice would mean two environments fighting over one
    Snowflake object.
  EOT
}

variable "create_env" {
  type        = bool
  default     = false
  description = <<-EOT
    Create one environment's database and its schemas. True for pre_prod
    and prod, false for shared.
  EOT
}

variable "env_database" {
  type        = string
  default     = null
  description = "Database this environment owns, e.g. PRE_PROD_DB. Required when create_env is true."

  validation {
    condition     = var.env_database == null || can(regex("^[A-Z][A-Z0-9_]*$", var.env_database))
    error_message = "env_database must be an uppercase Snowflake identifier, e.g. PRE_PROD_DB."
  }
}

variable "env_schemas" {
  type        = list(string)
  default     = ["BRONZE", "SILVER", "GOLD"]
  description = <<-EOT
    Medallion layers created inside env_database. Identical across
    environments today; a list rather than three resources so that adding a
    layer is a one-line tfvars change, and so drift between environments is
    visible as a diff rather than hidden in separate files.
  EOT
}

variable "warehouse_name" {
  type        = string
  default     = "ANALYSIS_WH"
  description = "Shared warehouse. Only used when create_shared is true."
}

variable "service_user_name" {
  type        = string
  default     = "GITHUB_ACTIONS_SERVICE_USER"
  description = "CI service user that runs Terraform. Only used when create_shared is true."
}

variable "service_user_rsa_public_key" {
  type        = string
  default     = null
  description = <<-EOT
    Public half of the service user's key pair. Safe to commit — it is a
    public key, and Snowflake needs it to verify the JWT that CI signs with
    the private half held in the SNOWFLAKE_PRIVATE_KEY_RAW secret.
  EOT
}
