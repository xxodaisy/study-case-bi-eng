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
        review_answer_timestamp::timestamp as review_answer_timestamp
    from source
)

select * from renamed