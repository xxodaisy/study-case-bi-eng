with source as (
    select * from {{ source('olist', 'customers') }}
),

renamed as(
    select
        customer_id,
        customer_unique_id     as unique_id,
        customer_zip_code_prefix as zip_code,
        COALESCE(customer_city, 'Unknown') as city,
        COALESCE(customer_state, 'Unknown') as state
    from source
)

select * from renamed