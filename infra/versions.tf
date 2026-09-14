terraform {
  required_version = ">= 1.16"

  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "~> 2.20"
    }
  }

  # State lives in HCP Terraform, one workspace per deployment target.
  # Workspaces are selected by TF_WORKSPACE rather than named here, so this
  # single root module serves budget-shared, budget-pre-prod, and
  # budget-prod without duplication. Execution stays local — HCP stores
  # state only, so Snowflake credentials never leave the machine or runner
  # that is applying.
  cloud {
    organization = "osusam28-main"

    workspaces {
      tags = ["budget"]
    }
  }
}
