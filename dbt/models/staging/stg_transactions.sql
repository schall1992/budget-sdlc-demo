{#
    Staging view over the raw budget export.

    The raw table stores money as currency-formatted text ("$75.17"), so the
    only real work here is parsing it. TRY_TO_DECIMAL is deliberate: a
    malformed value becomes NULL and is then caught by the not_null tests in
    schema.yml, which gives a clearer failure than a mid-build cast error.
    The not_null tests on outflow/inflow are therefore load-bearing, not
    boilerplate — they are what makes a silent parse failure loud.
#}

with source as (

    select * from {{ source('raw', 'transactions') }}

),

parsed as (

    select
        account,
        -- Already a DATE in the source; renamed only to avoid the reserved
        -- word, not cast.
        "DATE"          as transaction_date,
        payee,
        category_group,
        category,
        memo,

        -- Strip the currency symbol and any thousands separator. No value in
        -- the source carries a separator today, but stripping it costs
        -- nothing and stops a future one from parsing as NULL.
        try_to_decimal(replace(replace(outflow, '$', ''), ',', ''), 38, 2) as outflow,
        try_to_decimal(replace(replace(inflow, '$', ''), ',', ''), 38, 2)  as inflow

    from source

)

select
    *,
    -- Signed amount: money in is positive, money out is negative.
    inflow - outflow as amount

from parsed
