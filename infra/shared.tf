# Account-wide objects. Owned by the shared target so that pre_prod and
# prod never contend over them.

resource "snowflake_warehouse" "analysis_wh" {
  count = var.create_shared ? 1 : 0

  name                = var.warehouse_name
  warehouse_size      = "XSMALL"
  auto_suspend        = 60
  auto_resume         = "true"
  initially_suspended = true
}

resource "snowflake_service_user" "github_actions" {
  count = var.create_shared ? 1 : 0

  name         = var.service_user_name
  login_name   = var.service_user_name
  display_name = var.service_user_name
  disabled     = "false"
  default_role = "ACCOUNTADMIN"

  default_secondary_roles_option = "ALL"

  default_warehouse = snowflake_warehouse.analysis_wh[0].name

  rsa_public_key = var.service_user_rsa_public_key

  lifecycle {
    ignore_changes = [
      # OIDC workload identity is configured on this user out of band. It is
      # NOT currently working — the registered subject does not match the one
      # GitHub presents, and Snowflake exposes no way to read the registered
      # value back (only HAS_WORKLOAD_IDENTITY, a boolean). See
      # kb/observations/repo-and-cicd-baseline.md. Left ignored rather than
      # repaired because the per-environment key-pair users replacing it
      # retire this path entirely; remove this entry when they land.
      default_workload_identity,
      # Provider docs: external changes to these two aren't tracked because
      # their values change continuously on the Snowflake side.
      mins_to_unlock,
      days_to_expiry,
      # Provider claims this is "decided by the provider alone" and warns
      # this entry is redundant, but omitting it reintroduces a spurious
      # "update in-place" diff on every plan — keep it despite the warning.
      show_output,
    ]
  }
}
