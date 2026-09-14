{#
    Resolve a model's schema as <layer><suffix>, e.g. BRONZE or BRONZE_PR_12.

    The layer comes from the +schema config in dbt_project.yml (bronze for
    staging, gold for marts). The suffix comes from DBT_DEV_SCHEMA_SUFFIX,
    which is empty in every deployed context and set only for local
    development and per-PR builds.

    The '' default is load-bearing, not defensive: deploy-time compilation
    does not see environment variables at all, so without it `snow dbt
    deploy` fails to compile rather than producing an unsuffixed name.
#}

{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set layer = (custom_schema_name | trim) if custom_schema_name is not none else target.schema -%}
    {%- set suffix = env_var('DBT_DEV_SCHEMA_SUFFIX', '') | trim -%}

    {%- if suffix == '' -%}
        {{ layer | upper }}
    {%- else -%}
        {{ (layer ~ '_' ~ suffix) | upper }}
    {%- endif -%}

{%- endmacro %}
