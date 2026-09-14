# Production: built on merge to main.
#
# This target is deliberately never applied from a laptop. Its first apply is
# CI's, on merge to main — which is why the negative test proving the two
# roles cannot cross is the last task in the plan rather than part of this
# one.

create_shared = false
create_env    = true

env_database = "PROD_DB"

dbt_role_name = "PROD_DBT_ROLE"
dbt_user_name = "PROD_DBT_USER"

# Prod has only the three Terraform-managed schemas — no per-PR or
# per-developer builds — so it must not be able to create more.
grant_create_schema = false

# Public key. Committed deliberately. The private half went straight from
# openssl into the PROD_DBT_PRIVATE_KEY secret in the prod GitHub
# environment and was never written to disk, so there is no local copy to
# leak and no way to recover it — rotating means generating a new pair.
dbt_user_rsa_public_key = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAziokNhWsCp2LZ1w+naXcyAEOf2oGxTbl1iM5RpoEQFYV+yP44HWSZXCZPmSpcgY9IHo3zZ+sQrKdr0VNH2C6TTKCvnAXgBayhSCrTr6yUnOB6rih/k/CLJyqHMLHuk0C55NlF4RZbj8h0cnxr24d/FWAYN56b3wGejc7TcZ/X8jL+A612+fmUTXntxioMdgZWnVx6so8QaVni11Z9QouvhdFMIWXy/a2jMQa+cOlHr98BvwEQeK9EKRlQiaLCGHXEjEFsbn8uRLZR/EA8N+7nkdR0c2ymJXL4SD8vYNZZM9q8vdGvR3AR/FlznvaLzxj2kQ0beh5PHt1UzNe7ry3WQIDAQAB"
