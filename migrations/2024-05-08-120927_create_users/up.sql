-- Your SQL goes here
create table users (
    id serial primary key,
    email character varying(255) not null
);

create unique index users_email_uq on users(email);