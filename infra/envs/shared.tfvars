# Account-wide objects: the warehouse and the CI service user.
# No database or schemas — those belong to the environment targets.

create_shared = true
create_env    = false

warehouse_name    = "ANALYSIS_WH"
service_user_name = "GITHUB_ACTIONS_SERVICE_USER"

# Public key. Committed deliberately; the private half lives only in the
# SNOWFLAKE_PRIVATE_KEY_RAW GitHub secret.
service_user_rsa_public_key = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAyqFJSBl3A8GrDFZ8CpSUJnZsy9nxgD3qhXli8byz0KNMsoD++KD11Y719RJS+TbDg6EeDZt5UfwERL1YWkhbGrqkibtfeUU0OBbjwLHSW0RvXNRH3x8ONC0H5ty/nNNTq1EVODLT5A9Xl+pi9V194xoYW2BuvdYd5yaDB0gS9P7MmM8tRvjy4Ibrz5ayif/P2af+hBUibK4jD4NAoVYVSvtGiU+LKcn5T02m3GybSO1nwN/HkFdSwn9DMg9r/+r80eQazEjWsWwHpHqzJZ0vG1odB+co0Lk/PXs6XfmF2tAKb0FeWZtKopIrFdqaa0tFRveZyCeB7ghPZWOs8bScFQIDAQAB"
