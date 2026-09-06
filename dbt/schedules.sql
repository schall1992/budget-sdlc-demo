-- To avoid issues with CREATE OR ALTER, suspend all of the tasks from root to child
-- ALTER TASK IF EXISTS ensures this file can execute on first run each time a task is added
ALTER TASK IF EXISTS run_budget_subset SUSPEND;
ALTER TASK IF EXISTS run_budget_full SUSPEND;

-- Builds a subset of the models and runs tests. This is an example of a subset that needs
-- to be available early for business needs — update the --select list to match real models.
CREATE OR ALTER TASK run_budget_subset
  WAREHOUSE = budget_dbt_wh
  SCHEDULE = '12 hours'
  AS
      execute dbt project budget_dbt_object_gh_action args='build --select raw_customers stg_customers customers --target prod';

-- Builds all models and runs tests in DAG order, failing early if any test fails
CREATE OR ALTER TASK run_budget_full
  WAREHOUSE = budget_dbt_wh
  AFTER run_budget_subset
  AS
      execute dbt project budget_dbt_object_gh_action args='build --target prod';

-- When a task is first created or if an existing task it paused, it MUST BE RESUMED to be activated
-- The tasks must be enabled in REVERSE ORDER from child to root
ALTER TASK IF EXISTS run_budget_full RESUME;
ALTER TASK IF EXISTS run_budget_subset RESUME;
