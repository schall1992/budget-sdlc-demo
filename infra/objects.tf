resource "snowflake_warehouse" "analysis_wh" {
  name              = "ANALYSIS_WH"
  warehouse_size    = "XSMALL"
  auto_suspend      = 60
  auto_resume       = "true"
  initially_suspended = true
}

resource "snowflake_database" "pre_prod" {
  name = "PRE_PROD_DB"
}

resource "snowflake_database" "prod" {
  name = "PROD_DB"
}

resource "snowflake_schema" "pre_prod_bronze" {
  name     = "BRONZE"
  database = snowflake_database.pre_prod.name
}

resource "snowflake_schema" "pre_prod_silver" {
  name     = "SILVER"
  database = snowflake_database.pre_prod.name
}

resource "snowflake_schema" "pre_prod_gold" {
  name     = "GOLD"
  database = snowflake_database.pre_prod.name
}

resource "snowflake_schema" "prod_bronze" {
  name     = "BRONZE"
  database = snowflake_database.prod.name
}

resource "snowflake_schema" "prod_silver" {
  name     = "SILVER"
  database = snowflake_database.prod.name
}

resource "snowflake_schema" "prod_gold" {
  name     = "GOLD"
  database = snowflake_database.prod.name
}
