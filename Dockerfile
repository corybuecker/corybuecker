FROM rust:1.78.0 AS backend_builder
RUN mkdir -p /build
COPY Cargo.lock Cargo.toml /build/
COPY src /build/src
WORKDIR /build
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/build/target \
    cargo build --release
RUN --mount=type=cache,target=/build/target cp /build/target/release/blog /build/blog

FROM node:alpine as frontend_builder
RUN mkdir -p /static
COPY assets /assets
COPY templates /templates
WORKDIR /assets
RUN npm ci
RUN npx tailwindcss -i css/app.css -o app.css
RUN npx esbuild --bundle js/app.ts --external:highlight.js --external:htmx.org --format=esm > app.js

FROM rust:1.78.0-slim
COPY --from=backend_builder /build/blog /app/blog
COPY static /app/static
COPY templates /app/templates
COPY --from=frontend_builder /assets/app.css /assets/app.js /app/static/
WORKDIR /app
CMD ["/app/blog"]