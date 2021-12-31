FROM elixir:slim AS elixir_builder
RUN apt update && apt-get install -y git
RUN mix local.hex --force
RUN mix local.rebar --force
COPY mix.exs mix.lock /app/
WORKDIR /app
RUN mix deps.get
RUN mix deps.compile

FROM node:alpine AS node_builder
COPY assets/package.json assets/package-lock.json /app/assets/
WORKDIR /app/assets
RUN npm install

FROM elixir_builder AS content_builder
COPY . /app

COPY --from=node_builder /app/assets/node_modules /app/assets/node_modules
RUN mix tailwind default
RUN mix esbuild default

RUN mix run -e "Blog.assets()"
RUN mix run -e "Blog.hello()"

FROM nginx:alpine
COPY --from=content_builder /app/output /usr/share/nginx/html
