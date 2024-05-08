-- Your SQL goes here
create table pages (
    id serial primary key,
    slug character varying(128) not null,
    title character varying(255) not null,
    published timestamp with time zone,
    preview text,
    description text not null,
    content text not null,
    created_at timestamp with time zone not null default now(),
    updated_at timestamp with time zone not null
);
