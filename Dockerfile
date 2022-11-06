FROM elixir:slim AS elixir_builder
RUN mix local.hex --force
RUN mix local.rebar --force
COPY mix.exs mix.lock /app/

WORKDIR /app

RUN mix deps.get
RUN mix deps.compile

COPY assets /app/assets
COPY config /app/config
COPY content /app/content
COPY lib /app/lib
COPY templates /app/templates

RUN mix tailwind default
RUN mix esbuild default

RUN mix run -e "Blog.assets()"
RUN mix run -e "Blog.hello()"

FROM caddy:alpine
COPY --from=elixir_builder /app/output /usr/share/caddy
COPY Caddyfile /etc/caddy/Caddyfile
