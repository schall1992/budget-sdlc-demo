{#
    Fails on any negative value. Distinct from is_positive_amount, which
    also rejects zero — see schema.yml on stg_transactions for why a budget
    ledger's outflow and inflow columns are legitimately zero.
#}

{% test is_non_negative(model, column_name) %}

select *
from {{ model }}
where {{ column_name }} < 0

{% endtest %}
