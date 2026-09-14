# One environment's dbt identity: a role that owns everything in that
# environment's database, a service user that can assume only that role, and
# the grants the role needs to build. Gated on the same create_env as the
# database itself — the identity and the thing it owns are never separable.

resource "snowflake_account_role" "dbt" {
  count = var.create_env ? 1 : 0

  name    = var.dbt_role_name
  comment = "dbt build role for ${var.env_database}. Owns every schema in that database and can read SOURCE_DB."

  lifecycle {
    precondition {
      condition     = !var.create_env || (var.dbt_role_name != null && var.dbt_user_name != null)
      error_message = "create_env is true but dbt_role_name/dbt_user_name are unset — the target's tfvars file is incomplete."
    }
  }
}

resource "snowflake_service_user" "dbt" {
  count = var.create_env ? 1 : 0

  name         = var.dbt_user_name
  login_name   = var.dbt_user_name
  display_name = var.dbt_user_name
  disabled     = "false"

  default_role      = snowflake_account_role.dbt[0].name
  default_warehouse = var.warehouse_name

  # The whole point of this change: a leaked pre_prod credential must not be
  # able to reach PROD_DB. Secondary roles ALL would hand the session every
  # role the user holds, which is what makes a "default role" cosmetic rather
  # than a boundary.
  default_secondary_roles_option = "NONE"

  rsa_public_key = var.dbt_user_rsa_public_key

  lifecycle {
    ignore_changes = [
      # Values Snowflake changes on its own; see shared.tf for the same list.
      mins_to_unlock,
      days_to_expiry,
      show_output,
    ]
  }
}

# The user can assume its own role and nothing else.
resource "snowflake_grant_account_role" "dbt_to_user" {
  count = var.create_env ? 1 : 0

  role_name = snowflake_account_role.dbt[0].name
  user_name = snowflake_service_user.dbt[0].name
}

# ACCOUNTADMIN inherits through SYSADMIN, so it keeps effective control of
# the schemas it is about to hand ownership of — and Terraform can keep
# managing them.
resource "snowflake_grant_account_role" "dbt_to_sysadmin" {
  count = var.create_env ? 1 : 0

  role_name        = snowflake_account_role.dbt[0].name
  parent_role_name = "SYSADMIN"
}

resource "snowflake_grant_privileges_to_account_role" "warehouse" {
  count = var.create_env ? 1 : 0

  account_role_name = snowflake_account_role.dbt[0].name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "WAREHOUSE"
    object_name = var.warehouse_name
  }
}

resource "snowflake_grant_privileges_to_account_role" "database" {
  count = var.create_env ? 1 : 0

  account_role_name = snowflake_account_role.dbt[0].name

  # CREATE SCHEMA is what lets pre_prod build the per-developer and per-PR
  # suffixed schemas. Prod has no dynamic schemas, so it does not get it.
  privileges = var.grant_create_schema ? ["USAGE", "CREATE SCHEMA"] : ["USAGE"]

  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.env[0].name
  }
}

# Ownership of the static medallion schemas, so dbt can write into them
# without per-object grants. Databases stay owned by ACCOUNTADMIN; only
# schemas transfer.
resource "snowflake_grant_ownership" "schemas" {
  for_each = var.create_env ? toset(var.env_schemas) : toset([])

  account_role_name = snowflake_account_role.dbt[0].name

  # Preserve any privileges already granted on the schema rather than
  # dropping them as ownership moves.
  outbound_privileges = "COPY"

  on {
    object_type = "SCHEMA"
    object_name = snowflake_schema.env[each.value].fully_qualified_name
  }
}

# Read access to the raw source. SOURCE_DB is not Terraform-managed, so these
# are grants on a database this module does not own — see the spec's Grants
# section. Recorded so it is not later mistaken for drift.
resource "snowflake_grant_privileges_to_account_role" "source_database" {
  count = var.create_env ? 1 : 0

  account_role_name = snowflake_account_role.dbt[0].name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "DATABASE"
    object_name = var.source_database
  }
}

resource "snowflake_grant_privileges_to_account_role" "source_schema" {
  count = var.create_env ? 1 : 0

  account_role_name = snowflake_account_role.dbt[0].name
  privileges        = ["USAGE"]

  on_schema {
    schema_name = "\"${var.source_database}\".\"${var.source_schema}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "source_tables" {
  count = var.create_env ? 1 : 0

  account_role_name = snowflake_account_role.dbt[0].name
  privileges        = ["SELECT"]

  on_schema_object {
    all {
      object_type_plural = "TABLES"
      in_schema          = "\"${var.source_database}\".\"${var.source_schema}\""
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "source_future_tables" {
  count = var.create_env ? 1 : 0

  account_role_name = snowflake_account_role.dbt[0].name
  privileges        = ["SELECT"]

  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = "\"${var.source_database}\".\"${var.source_schema}\""
    }
  }
}
