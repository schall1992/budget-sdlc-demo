# Account-wide objects: the warehouse and the CI service user.
# No database or schemas — those belong to the environment targets.

create_shared = true
create_env    = false

warehouse_name    = "ANALYSIS_WH"
service_user_name = "GITHUB_ACTIONS_SERVICE_USER"

# Public key. Committed deliberately; the private half lives only in the
# SNOWFLAKE_PRIVATE_KEY_RAW GitHub secret, in the `infra` environment.
#
# Rotated 2026-09-14: the secret had to move from the `prod` environment to
# `infra`, and GitHub will not read a secret back, so the pair was replaced
# rather than copied. The previous public key is in git history if the old
# private half ever resurfaces and needs matching to it.
service_user_rsa_public_key = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA6PRcG0IyOrpNIBVrXjFstlQpI1zg86cywhfKL1TKcMapTE9IcWKvQwTn1ROVwf0sPurmiAhBEnGw0Nk73VsFWj5OUem9hy1VJqv55u2Cl11nTUzu9wjXYNkelsQwhzlxoJnp+wXXxJ4/iroYOxwNomkfwFwujd+kTHDqy5nzLTm7L2mQ3mPDBu/IsltW15vAX6auGw9MEFZ7qp39ZceynuW1BoB7RbRZZl/+GIvuEFsv7bI8Xc3Q3X/fE1NGyKkewdt4UWoTcNx9Z5d/YcTNep6D40F9NDK/eqRL0hBMEBaRqvcWTghQrg5WbVMDZ/q0D4Q9W1K4JRHNzYcfJExMWwIDAQAB"
# throwaway: intentionally invalid to prove the required check blocks the PR
this is not valid hcl {{{
