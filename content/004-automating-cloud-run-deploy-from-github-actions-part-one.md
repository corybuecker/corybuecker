---
title: Automating a Cloud Run deploy from GitHub Actions, part 1
published: 2019-12-19T09:00:00Z
revised: 2020-01-09T13:05:00Z
draft: false
preview: In a previous post, I [setup up a Cloud Run (GCR) service to host a static site](/post/how-to-run-a-static-site-in-google-cloud-run/) with an NGINX-based Docker image. GitHub hosts the underlying Next.js project. GitHub Actions can automate building and deploying each change to the repository. This requires a little extra work to setup permissions to for Google's Container Registry and Cloud Run services.
description: Setup the permissions and roles for automatically deploying a Cloud Run (GCR) service to Github Actions.
slug: automating-cloud-run-deploy-from-github-actions-part-one
---

In a previous post, I [setup up a Cloud Run (GCR) service to host a static site](/post/how-to-run-a-static-site-in-google-cloud-run/) with an NGINX-based Docker image. 

GitHub hosts the underlying Next.js project. GitHub Actions can automate building and deploying each change to the repository. This requires a little extra work to setup permissions to for Google's Container Registry and Cloud Run services.

## Initialize Container Registry storage

Push a simple image to Container Registry to create the Cloud Storage bucket. This avoids assignment of bucket administration permissions to the service account.

```bash
gcloud auth configure-docker
docker pull hello-world
docker tag hello-world gcr.io/PROJECT-ID/hello-world:latest
docker push gcr.io/PROJECT-ID/hello-world:latest
```

## Create a custom role

Create a new role and assign the role the following permissions for the Container Registry and Cloud Run:

- storage.buckets.get
- run.services.create
- run.services.get
- run.services.list
- run.services.update

```bash
gcloud iam roles create github_actions \
    --project=PROJECT-ID \
    --title="GitHub Actions"

gcloud iam roles update github_actions \
    --project=PROJECT-ID \
    --stage=GA \
    --permissions=storage.buckets.get,run.services.create,run.services.get,run.services.list,run.services.update
```

## Create a service account

Google recommends using the [principle of least privilege](https://en.wikipedia.org/wiki/Principle_of_least_privilege) when [assigning a service account to run a particular Cloud Run service](https://cloud.google.com/run/docs/securing/service-identity).

In order to make things a _bit_ more convenient I am sharing a single service account for both the Container Registry and Cloud Run services. If you prefer, an alternative is to use two service accounts and two jobs in GitHub Actions to separate the permissions. My rationale is that a data breach in GitHub would likely expose both service account keys anyway.

Create the dedicated service account.

```bash
gcloud iam service-accounts create github-actions \
    --display-name="GitHub Actions"
```

Create and download a service account key file.

```bash
gcloud iam service-accounts keys create github_actions_key.json \
    --iam-account=github-actions@PROJECT_ID.iam.gserviceaccount.com
```

## Assign the custom role

Now that the service account and custom role have been created, it is time to assign the custom role to the new service account.

```bash
gcloud projects add-iam-policy-binding PROJECT_ID \
    --member serviceAccount:github-actions@PROJECT_ID.iam.gserviceaccount.com \
    --role projects/PROJECT_ID/roles/github_actions
```

## Assign Container Registry bucket permissions

Under Storage > Browser, find the bucket containing the Docker images. It is usually a bucket whose name starts with `artifacts`.

Add the Storage Admin permission for this bucket to the service account created earlier. This will allow that service account to push Docker images into the Storage used by Cloud Registry.

```bash
gsutil iam ch serviceAccount:github-actions@PROJECT_ID.iam.gserviceaccount.com:roles/storage.admin gs://BUCKET_NAME
```

## Allow service account to act as itself

This was an unusual step required by Cloud Run. Cloud Run uses a [provided service account](https://cloud.google.com/run/docs/securing/service-identity?hl=en#runtime_service_account) as its identity when running a service. This is a great feature to limit the access of the running container.

However, we have to allow the GitHub Actions service account to [act as itself in order to deploy a service it will be running](https://cloud.google.com/run/docs/reference/iam/roles#additional-configuration).

```bash
gcloud iam service-accounts add-iam-policy-binding github-actions@PROJECT_ID.iam.gserviceaccount.com \
    --member="serviceAccount:github-actions@PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser"
```

## Deploy to Cloud Run

It is a good idea to load the service account locally to test the following steps.

```bash
gcloud auth activate-service-account --key-file PATH-TO-JSON-KEY
```

If you need to switch back to your primary user run this command.

```bash
gcloud config set account user@example.com
```    

At this point you can deploy to Cloud Run with the new service account.

```bash
gcloud run deploy nginx \
    --image gcr.io/PROJECT-ID/nginx:$(git rev-parse HEAD) \
    --service-account github-actions@PROJECT-ID.iam.gserviceaccount.com \
    --platform managed \
    --region us-central1 \
    --allow-unauthenticated
```

In [part 2](/post/automating-cloud-run-deploy-from-github-actions-part-two), I connect the new service account to GitHub Actions.

_Revision note (2019-12-27)_

The service account does not have permission to allow unauthenticated access to Cloud Run services. I'll investigate further. The easiest workaround for the moment is to use the project owner user to deploy the service the first time. This only has to be done once, and the permission will remain on each subsequent deploy by the service account.