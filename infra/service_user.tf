resource "snowflake_service_user" "github_actions" {
  name         = "GITHUB_ACTIONS_SERVICE_USER"
  login_name   = "GITHUB_ACTIONS_SERVICE_USER"
  display_name = "GITHUB_ACTIONS_SERVICE_USER"
  disabled     = "false"
  default_role = "ACCOUNTADMIN"

  default_secondary_roles_option = "ALL"

  default_warehouse = snowflake_warehouse.analysis_wh.name

  rsa_public_key = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAyqFJSBl3A8GrDFZ8CpSUJnZsy9nxgD3qhXli8byz0KNMsoD++KD11Y719RJS+TbDg6EeDZt5UfwERL1YWkhbGrqkibtfeUU0OBbjwLHSW0RvXNRH3x8ONC0H5ty/nNNTq1EVODLT5A9Xl+pi9V194xoYW2BuvdYd5yaDB0gS9P7MmM8tRvjy4Ibrz5ayif/P2af+hBUibK4jD4NAoVYVSvtGiU+LKcn5T02m3GybSO1nwN/HkFdSwn9DMg9r/+r80eQazEjWsWwHpHqzJZ0vG1odB+co0Lk/PXs6XfmF2tAKb0FeWZtKopIrFdqaa0tFRveZyCeB7ghPZWOs8bScFQIDAQAB"

  lifecycle {
    ignore_changes = [
      # OIDC workload identity is already configured on this user (used by
      # the dbt workflows via the Snowflake CLI) and is out of scope here —
      # the provider attribute for it is experimental. Leave it untouched.
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
