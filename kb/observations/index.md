# Observations

Durable facts about the environment and the codebase — what a future session
would otherwise have to rediscover.

- [snowflake-account-baseline.md](snowflake-account-baseline.md) — project
  infrastructure now exists: ANALYSIS_WH, PRE_PROD_DB (bronze/silver/gold),
  PROD_DB (bronze/silver/gold), all Terraform-managed. Source data in
  SOURCE_DB.RAW.TRANSACTIONS.
- [dbt-scaffold-drift.md](dbt-scaffold-drift.md) — template placeholders
  and stale tasty-bytes references. The raw-data-location contradiction is
  resolved (no raw schema; SOURCE_DB is authoritative).
- [github-actions-service-user-bootstrap.md](github-actions-service-user-bootstrap.md)
  — `github_actions_service_user` was hand-created via Cortex ahead of
  Terraform, with both OIDC and key-pair auth; imported into Terraform
  state, default_warehouse now set to ANALYSIS_WH.
