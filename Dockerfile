FROM node:16.2.0-alpine AS builder

COPY . /app
WORKDIR /app
RUN npm install --production
RUN npx webpack --config webpack.production.config.js
RUN npx tsc
RUN node dist/compile_markdown.js

FROM nginx:mainline-alpine

COPY --from=builder /app/output/ /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf