# One environment's objects. Instantiated once per environment workspace,
# with env_database telling it which environment it is.

resource "snowflake_database" "env" {
  count = var.create_env ? 1 : 0

  name = var.env_database

  lifecycle {
    precondition {
      condition     = !var.create_env || var.env_database != null
      error_message = "create_env is true but env_database is unset — the target's tfvars file is incomplete."
    }
  }
}

resource "snowflake_schema" "env" {
  for_each = var.create_env ? toset(var.env_schemas) : toset([])

  name     = each.value
  database = snowflake_database.env[0].name
}
