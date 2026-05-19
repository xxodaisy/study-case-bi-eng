with source as (
    select * from {{ source('olist', 'products') }}
),

category_translation as (
    select * from {{ ref('stg_category_translation') }}
),

renamed as (
    select
        s.product_id,
        s.product_category_name,
        ct.category_name_english,
        s.product_name_lenght        as product_name_length,
        s.product_description_lenght as description_length,
        s.product_photos_qty         as photos_qty,
        s.product_weight_g           as weight_g,
        s.product_length_cm          as length_cm,
        s.product_height_cm          as height_cm,
        s.product_width_cm           as width_cm
    from source s
    left join category_translation ct
        on s.product_category_name = ct.product_category_name
)

select * from renamed