FROM elixir:1.14.3-alpine as deps

ENV MIX_ENV=prod
COPY mix.lock mix.exs /src/

WORKDIR /src

RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix deps.get
RUN mix deps.compile

COPY config /src/config
RUN mix esbuild.install
RUN mix tailwind.install

FROM elixir:1.14.3-alpine as builder

COPY assets /src/assets
COPY config /src/config
COPY content /src/content
COPY lib /src/lib
COPY templates /src/templates
COPY mix* /src

COPY --from=deps /src/deps /src/deps
COPY --from=deps /src/_build /src/_build
RUN mix local.hex --force
RUN mix local.rebar --force

WORKDIR /src

RUN mix build

FROM caddy:2.6.4

COPY --from=builder /src/output/ /usr/share/caddy/
COPY Caddyfile /etc/caddy/Caddyfile
