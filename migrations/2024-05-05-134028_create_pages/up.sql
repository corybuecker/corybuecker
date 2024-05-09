-- Your SQL goes here
create table pages (
    id serial primary key,
    slug character varying(128) not null,
    title character varying(255) not null,
    preview text,
    description text not null,
    published_at timestamp with time zone,
    revised_at timestamp with time zone,
    content text not null,
    created_at timestamp with time zone not null default now(),
    updated_at timestamp with time zone not null
);

create unique index pages_slug_uq on pages(slug);