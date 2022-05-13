FROM elixir:slim AS elixir_builder
RUN apt update && apt-get install -y git curl
RUN curl -fsSL https://deb.nodesource.com/setup_17.x | bash -
RUN apt-get install -y nodejs
RUN mix local.hex --force
RUN mix local.rebar --force
COPY mix.exs mix.lock package.json package-lock.json /app/

WORKDIR /app

RUN mix deps.get
RUN mix deps.compile
RUN npm install

COPY . /app

RUN mix tailwind default
RUN mix esbuild default

RUN mix run -e "Blog.assets()"
RUN mix run -e "Blog.hello()"

FROM caddy:alpine
COPY --from=elixir_builder /app/output /usr/share/caddy
COPY Caddyfile /etc/caddy/Caddyfile
