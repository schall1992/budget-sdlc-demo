-- A transaction is either money in or money out, never both and never
-- neither. Holds for all 1,738 source rows.
--
-- This catches what the per-column not_null and is_non_negative tests
-- cannot: the two currency columns being swapped, or one of them being
-- parsed from the wrong source column. Both would leave every per-column
-- test green.

select *
from {{ ref('stg_transactions') }}
where (outflow = 0) = (inflow = 0)
