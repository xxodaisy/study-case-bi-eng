with source as(
    select * from {{ source('olist', 'order_reviews') }}
),

renamed as(
    select
        review_id,
        order_id,
        review_score::integer as rating,
        COALESCE(review_comment_title, 'No title provided') as review_comment_title,
        COALESCE(review_comment_message, 'No message provided') as review_comment_message,
        review_creation_date::timestamp as reviewed_at,
        review_answer_timestamp::timestamp as review_answer_timestamp,
        case when review_score::integer <=2 then true else false end as is_low_score
    from source
)

select * from renamed
