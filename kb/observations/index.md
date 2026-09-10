# Observations

Durable facts about the environment and the codebase — what a future session
would otherwise have to rediscover.

- [snowflake-account-baseline.md](snowflake-account-baseline.md) — what exists
  in the Snowflake account (source table only), which CLI connection works,
  and everything the setup scripts have not yet created.
- [dbt-scaffold-drift.md](dbt-scaffold-drift.md) — template placeholders,
  stale tasty-bytes references, and the unresolved question of where raw data
  lives.
- [github-actions-service-user-bootstrap.md](github-actions-service-user-bootstrap.md)
  — `github_actions_service_user` was hand-created via Cortex ahead of
  Terraform, with both OIDC and key-pair auth; Terraform will need to
  `import` it rather than create it.
