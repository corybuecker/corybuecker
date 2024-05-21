FROM rust:alpine AS builder

RUN apk add --no-cache musl-dev

COPY . /build
WORKDIR /build
RUN cargo build -r