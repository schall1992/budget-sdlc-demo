-- Scheduled orchestration for the prod dbt project object.
--
-- NOT INVOKED BY ANY WORKFLOW. Nothing in CI creates, resumes, or schedules a
-- task; this file exists so the scheduling path is written down and ready, and
-- is run by hand if and when that is wanted. Run it as a role that can create
-- tasks in PROD_DB.BRONZE — PROD_DBT_ROLE owns the schema but is not granted
-- EXECUTE TASK, so that grant is a prerequisite.
--
-- The template's two-task DAG (a fast subset, then a full build) collapsed to
-- one task: there is a single model today, so a "subset" would select the same
-- thing the full build does. Split it again when the model count justifies it.

-- ALTER TASK IF EXISTS so this file is re-runnable, including on first run.
ALTER TASK IF EXISTS PROD_DB.BRONZE.run_budget_full SUSPEND;

-- Builds all models and runs tests in DAG order, failing early if any test fails.
CREATE OR ALTER TASK PROD_DB.BRONZE.run_budget_full
  WAREHOUSE = ANALYSIS_WH
  SCHEDULE = '12 hours'
  AS
      EXECUTE DBT PROJECT PROD_DB.BRONZE.budget_dbt args='build --target prod';

-- A newly created or suspended task must be resumed to become active.
ALTER TASK IF EXISTS PROD_DB.BRONZE.run_budget_full RESUME;
