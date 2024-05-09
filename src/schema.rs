// @generated automatically by Diesel CLI.

diesel::table! {
    pages (id) {
        id -> Int4,
        #[max_length = 128]
        slug -> Varchar,
        #[max_length = 255]
        title -> Varchar,
        preview -> Nullable<Text>,
        description -> Text,
        published_at -> Nullable<Timestamptz>,
        revised_at -> Nullable<Timestamptz>,
        content -> Text,
        created_at -> Timestamptz,
        updated_at -> Timestamptz,
    }
}

diesel::table! {
    users (id) {
        id -> Int4,
        #[max_length = 255]
        email -> Varchar,
    }
}

diesel::allow_tables_to_appear_in_same_query!(
    pages,
    users,
);
