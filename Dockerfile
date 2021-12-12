FROM node:alpine AS asset_builder
COPY assets /app/assets
COPY lib /app/lib
WORKDIR /app/assets
RUN npm install
RUN npm run deploy

FROM elixir:alpine
LABEL maintainer="Cory Buecker <email@corybuecker.com>"

ENV MIX_ENV=prod

RUN mix local.rebar --force
RUN mix local.hex --force

COPY mix.exs mix.lock /app/

WORKDIR /app

RUN mix deps.get
RUN mix deps.compile

COPY config /app/config
COPY lib /app/lib

RUN mix compile

COPY assets /app/assets
COPY priv /app/priv

COPY --from=asset_builder /app/assets/output/app.css /app/priv/static/assets/app.css

RUN mix assets.deploy

CMD ["mix", "phx.server"]