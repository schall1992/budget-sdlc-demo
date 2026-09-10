resource "snowflake_service_user" "github_actions" {
  name         = "GITHUB_ACTIONS_SERVICE_USER"
  login_name   = "GITHUB_ACTIONS_SERVICE_USER"
  display_name = "GITHUB_ACTIONS_SERVICE_USER"
  disabled     = "false"
  default_role = "ACCOUNTADMIN"

  default_secondary_roles_option = "ALL"

  rsa_public_key = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAtqFAf/6HThfkDwFW37OSG/4mMhJazS8HIyQ4Q0eyuPD55jAEIA0buBgA/ffaNki76DmTNQNu2HusU+VO7mbyAoEhsd1NvoLSabhJlHDRrc0kfwx5r0GeYUzWY8SZxque01R3CbiH75b1OiJdvv2XmhTQyOe+e7em5RBfWhdgZx7tgP96x4PG/mCsS3/uf0rnVMBMk9XYtS8wW/MRh45j6ZVCiILi/csbYBAe9HY0Ex+aoqq/Be0hDXJEeO5CRbM9usRv8xHROGI/oaInrZY/5wPLXCECABI8I4bLH+8EUhsdOpymgKKYP8v6YgMZO1aQNte7mSeztLI7Ur5RtvBhRQIDAQAB"

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
