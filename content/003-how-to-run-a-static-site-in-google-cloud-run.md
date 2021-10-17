---
title: How to run a static site in Google Cloud Run
published: 2019-12-08T12:54:36Z
draft: false
preview: Originally, I wanted to run this site in a Google Cloud Storage bucket. However, I wanted to have more control over some of the load balancer settings. Specifically, Cloud Storage buckets do not allow HTTPS unless the bucket is fronted by a Google Load Balancer or a third-party CDN. The simplest solution that also yields a significant amount of control is hosting via Google Cloud Run. Cloud Run is an inexpensive stateless container platform. It performs automatic HTTP to HTTPS redirect (without HSTS, see below) and it's trivial to run a custom NGINX image.
description: Originally, I wanted to run this site in a Google Cloud Storage bucket. However, I wanted to have more control over some of the load balancer settings. Specifically, Cloud Storage buckets do not allow HTTPS unless the bucket is fronted by a Google Load Balancer or a third-party CDN. The simplest solution that also yields a significant amount of control is hosting via Google Cloud Run. Cloud Run is an inexpensive stateless container platform. It performs automatic HTTP to HTTPS redirect (without HSTS, see below) and it's trivial to run a custom NGINX image.
slug: how-to-run-a-static-site-in-google-cloud-run
---

Originally, I wanted to run this site in a [Google Cloud Storage](https://cloud.google.com/storage/) bucket. However, I wanted to have more control over the load balancer settings. Specifically, Cloud Storage buckets do not allow HTTPS via a custom domain unless the bucket is fronted by a Google Load Balancer or a third-party CDN.

The simplest solution that also yields a significant amount of control is hosting via Google Cloud Run. [Cloud Run](https://cloud.google.com/run/) is an inexpensive stateless container platform. It performs automatic HTTP to HTTPS redirect (without HSTS, see below) and it's trivial to run a custom NGINX image.

First, follow the Cloud SDK [Quickstart guide](https://cloud.google.com/sdk/docs/quickstarts) for your platform.

## Configure Docker for Container Registry

Because I am using the fully managed version of Cloud Run, I can [only run containers from Cloud Registry](https://cloud.google.com/run/docs/deploying) images. This is very inexpensive, so I didn't mind.

I did have to configure my local Docker daemon with authentication to push to that registry.

```bash
gcloud auth configure-docker
```

## Create a Dockerfile

Create a simple Dockerfile in the root directory that will install Node packages in a builder step before compiling the blog content. This makes caching of each build step much faster.

The NGINX container serves static content with all of the header directives that I wanted to add.

```docker
FROM node:13.2-alpine AS builder

COPY package.json package-lock.json /build/
WORKDIR /build
RUN npm install

COPY . /build

ENV NODE_ENV=production

RUN npm run export

FROM nginx:mainline-alpine
COPY --from=builder /build/out /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
```

It's optional, but I highly recommend using a `.dockerignore` file to prevent `node_modules` and other large, unneeded directories from being loaded into the Docker build context.

## Create a NGINX configuration

Place an `nginx.conf` file in the root directory of your project. Be sure to change the `server_name` directive to match your domain.

```nginx
server {
    listen 8080;
    server_name yourdomain.com;

    gzip on;
    gzip_types text/html application/javascript text/css;

    expires 1y;

    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header Content-Security-Policy "default-src 'none'; font-src 'none'; img-src 'self'; object-src 'none'; script-src 'self'; style-src 'self'; frame-ancestors 'none'";
    add_header X-Frame-Options "DENY";
    add_header X-Content-Type-Options "nosniff";

    location / {
        root /usr/share/nginx/html;
        index index.html index.htm;
    }

    error_page 404 /404.html;
}
```

## Create and push the Docker image

Create the Docker image, tagging it for storage in [Google's Container Registry](https://cloud.google.com/container-registry/docs/).

```bash
docker build -t gcr.io/PROJECT-ID/image:latest .
```

Push the image to the registry.

```bash
docker push gcr.io/PROJECT-ID/image:latest
```

## Deploy to Cloud Run

Deploy the new image to Cloud Run. Substitute your service name and the image name created above.

```bash
gcloud run deploy SERVICE-NAME --image gcr.io/PROJECT-ID/image:latest
```

If you want the site to be publicly accessible, say "y" when asked if you want to allow unauthenticated invocations.

Once the deploy is complete, the application URL will be outputted. You can set up a CNAME record to that URL or [map a custom domain to that service](https://cloud.google.com/run/docs/mapping-custom-domains).
