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

RUN mix assets.deploy

CMD ["mix", "phx.server"]