---
title: Automating a Cloud Run deploy from GitHub Actions, part 2
published: 2019-12-29T17:49:03Z
draft: false
preview: With the service account set up, it's relatively simple to configure GitHub Actions to deploy when a branch is pushed.
description: With the service account set up, it's relatively simple to configure GitHub Actions to deploy when a branch is pushed.
slug: automating-cloud-run-deploy-from-github-actions-part-two
---

With the service account set up, it's relatively simple to configure GitHub Actions to deploy when a branch is pushed.

## Create GitHub secrets

Follow [GitHub's guide](https://help.github.com/en/actions/automating-your-workflow-with-github-actions/creating-and-using-encrypted-secrets#creating-encrypted-secrets) to create the following secrets:

--`CLOUDSDK_CORE_PROJECT`

This is the Google project ID, not the project name. The easiest way to find this is by running:

```bash
gcloud projects list
```

--`SERVICE_ACCOUNT_KEY`

The JSON service account key must be base64 encoded before being stored in GitHub secrets.

```bash
cat PATH_TO_SERVICE_KEY | base64
```

--`IMAGE_TAG`

This can be anything and will be used to name the Docker image.

--`CLOUD_RUN_SERVICE`

This can be anything and will be used by Cloud Run as the service name.

--`SERVICE_ACCOUNT`

This is the email address of the service account created in part one.

## Add workflow

In the repository, create a `main.yml` file in `.github/workflows`.

```yaml
name: Build and deploy to Cloud Run

on:
  push:
    branches:
      - main

env:
  CLOUDSDK_CORE_PROJECT: ${{ secrets.CLOUDSDK_CORE_PROJECT }}
  CLOUDSDK_RUN_PLATFORM: managed
  CLOUDSDK_RUN_REGION: us-central1

jobs:
  build-deploy:
    name: Build and deploy
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v2

      - uses: GoogleCloudPlatform/github-actions/setup-gcloud@0.1.2
        with:
          version: '274.0.1'
          service_account_key: ${{ secrets.SERVICE_ACCOUNT_KEY }}

      - name: Configure Docker
        run: gcloud auth configure-docker

      - name: Build image
        run: docker build -t ${{ secrets.IMAGE_TAG }}:${{ github.sha }} .

      - name: Push image
        run: docker push ${{ secrets.IMAGE_TAG }}:${{ github.sha }}

      - name: Deploy to Cloud Run
        run: >
          gcloud beta run deploy ${{ secrets.CLOUD_RUN_SERVICE }}-integration
          --image ${{ secrets.IMAGE_TAG }}:${{ github.sha }}
          --service-account ${{ secrets.SERVICE_ACCOUNT }}
```

On the next push to GitHub, the action will run.