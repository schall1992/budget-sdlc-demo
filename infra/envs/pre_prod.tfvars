# Pre-production: CI builds on pull requests, and local development.

create_shared = false
create_env    = true

env_database = "PRE_PROD_DB"

dbt_role_name = "PRE_PROD_DBT_ROLE"
dbt_user_name = "PRE_PROD_DBT_USER"

# Pre-prod builds per-developer and per-PR suffixed schemas, so it needs to
# create them. Prod does not.
grant_create_schema = true

# Public key. Committed deliberately; the private half lives only at
# ~/.snowflake/keys/pre_prod_dbt_user.p8 (mode 600) and in the
# PRE_PROD_DBT_PRIVATE_KEY GitHub secret.
dbt_user_rsa_public_key = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAtk6z1989TCk8xMUPfKqFgLk6zbFERcqhzThflNNnXFi3MT3ygNEnhCNReBM9P9OgKR3V4285aUvg5nTHIbO8kbazg7Bb+aZpPQK6tAcMh7C7OoY3NViFNGKO5DPiAVc5zHJfFmVWehADuktad7bTiCKI/pYb61OJwR9es/bcA1T4ju4e/e3gkdrby+BDjW3ygEbQxkfAk9J6z4mdH/S+IShXD00Ydz161FrczCCSkE5ECSUXaVBHL4fYCRj3G6Uo7CUEsZ2pVGv47nx2CFHmM11TnWoopK7PJ5dsFUSkB/8yMeIb0may+L5RnUR4bJXNlAAubUbRPYMN/jSE9kY/UwIDAQAB"
