/*
########################################bi-snippets########################################
This query defines a CTE (products) with sample customer-product subscriptions—each row 
an interval that may overlap others. It then uses window functions to assign each contiguous 
block of time a group ID and finally aggregates those groups into complete, non-overlapping
intervals per customer.
###########################################################################################
*/

with products as (
    select
        cast(customer_id    as int)     as customer_id,
        cast(product_id     as int)     as product_id,
        cast(date_from      as date)    as date_from,
        cast(date_to        as date)    as date_to
    from (values
        (20891, 10001, '2024-01-01', '2024-10-31'),
        (20891, 10001, '2025-01-01', '2025-12-31'),
        (20891, 10002, '2025-03-01', '2025-09-30'),
        (20891, 10003, '2025-05-15', '2025-06-15'),
        (20891, 10004, '2025-06-01', '2026-06-01'),
        (20891, 10005, '2025-04-03', '2025-06-01'),
        (20891, 10006, '2024-12-15', '2027-01-01'),
        (20891, 10007, '2025-06-15', '2025-07-15'),
        (20891, 10008, '2026-01-01', '2028-12-31'),
        (20891, 10009, '2025-02-01', '2025-05-31'),
        (20891, 10010, '2025-12-01', '2029-12-31'),
        (23472, 10001, '2025-01-01', '2025-03-31'),
        (23472, 10002, '2025-02-15', '2025-06-30'),
        (23472, 10003, '2025-04-01', '2025-04-30'),
        (23472, 10005, '2025-01-01', '2090-12-31'),
        (23472, 10006, '2025-05-01', '2025-07-15'),
        (23472, 10007, '2025-06-01', '2025-12-31'),
        (23472, 10008, '2025-03-01', '2025-03-15'),
        (23472, 10009, '2025-02-01', '2090-12-31'),
        (23472, 10010, '2025-07-01', '2026-07-01'),
        (34567, 10001, '2025-01-10', '2026-01-09'),
        (34567, 10002, '2025-01-10', '2025-02-09'),
        (34567, 10003, '2025-02-10', '2025-03-09'),
        (34567, 10004, '2025-03-10', '2025-04-09'),
        (34567, 10005, '2025-04-10', '2026-04-09'),
        (34567, 10006, '2025-06-01', '2025-12-31'),
        (34567, 10007, '2025-05-15', '2026-05-14'),
        (34567, 10008, '2026-01-01', '2027-01-01'),
        (45678, 10001, '2025-02-01', '2025-03-01'),
        (45678, 10001, '2025-06-01', '2026-06-01'),
        (45678, 10002, '2025-06-15', '2025-08-15'),
        (45678, 10003, '2025-07-01', '2025-07-31'),
        (45678, 10004, '2025-06-01', '2025-06-30'),
        (45678, 10005, '2025-06-15', '2090-12-31'),
        (45678, 10006, '2025-05-01', '2025-05-31'),
        (45678, 10007, '2025-08-01', '2025-12-31'),
        (45678, 10008, '2025-12-01', '2028-12-31')
    ) as product_values(customer_id, product_id, date_from, date_to)
)

select
  customer_id,
  interval_id,
  min(date_from)                        as interval_start,
  max(date_to)                          as interval_end
from (
        select
            customer_id,
            date_from,
            date_to,
            sum(
            case
                when last_interval_end is null or date_from > last_interval_end then 1
                else 0
            end
            ) over (partition by customer_id order by date_from) as interval_id
        from (
            select
                customer_id,
                date_from,
                date_to,
                max(date_to) over (
                    partition by customer_id
                    order by date_from
                    rows between unbounded preceding and 1 preceding
                ) as last_interval_end
            from products
        ) AS intervals
    ) AS numbered
group by customer_id, interval_id
order by customer_id, interval_id;