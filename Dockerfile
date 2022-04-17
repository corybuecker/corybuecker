FROM node:alpine AS builder-a

COPY package.json /app/package.json
COPY package-lock.json /app/package-lock.json

WORKDIR /app

COPY assets /app/assets

RUN npm install
RUN npm run build

FROM ruby:3.1.2-alpine as builder-b

COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock

WORKDIR /app

RUN bundle

COPY . /app
COPY --from=builder-a /app/output /app/output

RUN rake build

FROM caddy:alpine
COPY --from=builder-b /app/output /usr/share/caddy
COPY Caddyfile /etc/caddy/Caddyfile
