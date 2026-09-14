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

variable "dbt_role_name" {
  type        = string
  default     = null
  description = "Role that owns this environment's schemas, e.g. PRE_PROD_DBT_ROLE. Required when create_env is true."
}

variable "dbt_user_name" {
  type        = string
  default     = null
  description = "Service user for this environment's dbt builds. Required when create_env is true."
}

variable "dbt_user_rsa_public_key" {
  type        = string
  default     = null
  description = <<-EOT
    Public half of this environment's dbt service-user key pair. Safe to
    commit. The private half lives only in ~/.snowflake/keys (pre_prod) or a
    GitHub environment secret (prod) — never in this repo.
  EOT
}

variable "grant_create_schema" {
  type        = bool
  default     = false
  description = <<-EOT
    Grant CREATE SCHEMA on this environment's database. True for pre_prod,
    which builds per-developer and per-PR suffixed schemas; false for prod,
    which has only the three Terraform-managed ones.
  EOT
}

variable "source_database" {
  type        = string
  default     = "SOURCE_DB"
  description = "Raw source database. Not Terraform-managed — this module only grants read on it."
}

variable "source_schema" {
  type        = string
  default     = "RAW"
  description = "Schema within source_database holding the raw tables."
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
