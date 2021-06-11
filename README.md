# GitHub Action: Helm Chart Deployment

[![Status](https://github.com/bryk-io/chart-deploy-action/actions/workflows/publish.yml/badge.svg)](https://github.com/bryk-io/chart-deploy-action/actions/workflows/publish.yml)
[![Version](https://img.shields.io/github/tag/bryk-io/chart-deploy-action.svg)](https://github.com/bryk-io/chart-deploy-action/releases)
[![Software License](https://img.shields.io/badge/license-BSD3-red.svg)](LICENSE)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-v2.0-ff69b4.svg)](.github/CODE_OF_CONDUCT.md)

A GitHub action to run helm chart deployments operations.

## Usage

### Pre-requisites

1. Setup your environment. [More information.](https://docs.github.com/en/actions/reference/environments)
2. Add the required `KUBECTL_CONFIG` and `CHART_VALUES` [secrets](https://docs.github.com/en/actions/reference/environments#environment-secrets) to the environment.
3. Add this action as a step on your deployment workflow.

Both secrets most be properly encoded in base64.

```shell
cat values.yml | base64
```

### Inputs

- `name`: Deployment name. __Required__.
- `namespace`: Kubernetes namespace used for the deployment. __Required__.
- `version`: Specific application version to deploy. Will be used as image tag. Works with
   or without the `v` prefix, for example `0.1.0` or `v0.1.0`
- `charts`: Relative path to the charts inside the repository. (defaults to `helm/*`)
- `atomic`: The deployment process rolls back changes made in case of error.
- `no-hooks`: Prevent hooks from running during install.
- `force`: Force resource updates through a replacement strategy.
- `timeout`: Time to wait for any individual Kubernetes operations. (defaults to `5m0s`)

Sample step configuration.

```yaml
steps:
  - name: Helm chart deployment
    uses: bryk-io/chart-deploy-action@v1.0.0
    # example with all parameters
    with:
      name: my-deployment     # required
      namespace: dev          # required
      version: v0.1.0         # optional
      charts: deploy/my-chart # optional
      atomic: yes             # optional
      no-hooks: yes           # optional
      force: yes              # optional
      timeout: 8m30s          # optional
    env:
      KUBECTL_CONFIG: ${{ secrets.KUBECTL_CONFIG }} # required
      CHART_VALUES: ${{ secrets.CHART_VALUES }}     # required
```

> __Note:__ For the `version` parameter to work properly, the chart must support
  the value `image.tag` or `image.version` and use it to adjust the container image
  being deployed. For example:

```yaml
containers:
  - name: {{ .Chart.Name }}
    image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion | trimPrefix "v" }}"
    imagePullPolicy: {{ .Values.image.pullPolicy }}
```

## Workflow

Sample workflow file.

```yaml
name: deploy-dev
on:
  # To manually run deployments
  workflow_dispatch: {}
  # To automatically run deployments for tagged releases
  push:
    tags:
      - '*'
jobs:
  # Deploy helm chart
  deploy:
    name: run deployment
    runs-on: ubuntu-latest
    timeout-minutes: 10
    # Using a specific environment
    environment: dev
    steps:
      # Checkout code
      - name: Checkout repository
        uses: actions/checkout@v2

      # Deploy chart
      - name: Helm chart deployment
        uses: bryk-io/chart-deploy-action@v1.0.0
        with:
          name: my-deployment
          namespace: dev
        env:
          KUBECTL_CONFIG: ${{ secrets.KUBECTL_CONFIG }}
          CHART_VALUES: ${{ secrets.CHART_VALUES }}
```

To manually trigger this workflow using GitHub's CLI tool.

```shell
gh workflow run deploy-dev
```

## Without Environments

Setting up and using GitHub environments is recommended but not required to use this action.
Alternatively you can use a single workflow and combination of Kubernetes namespaces to manage
isolated deployments. There are some pros and cons to this approach to consider though.

### Pros

- Only a single workflow file is required to be enabled on the repository.
- The secrets used to configure a specific namespace can then be managed at the
  organization level and shared across several projects simplifying administration.

### Cons

- You'll loose integration with GitHub's UI for deployments, and potentially related
  features and tooling released in the future.

### How To

1. Create a Kubernetes namespace for the environment you wanna use for the deployment.
   For example `dev`.
2. Create organization or repository secrets to hold the Kubectl configuration and specific
   chart values. Name the secrets using the specific namespace as prefix, for example:
   `KUBECTL_CONFIG_DEV` and `CHART_VALUES_DEV`.
3. Use this action with proper values for the required parameters.

Sample workflow file.

```yaml
name: deploy
on:
  # Manual deployment
  workflow_dispatch:
    inputs:
      deployment:
        description: 'Deployment name'
        required: true
        default: 'echo-server'
      namespace:
        description: 'Kubernetes namespace to deploy into'
        required: true
      version:
        description: 'Specific application version to deploy (used as image tag)'
        required: false
        default: ''
jobs:
  deploy:
    name: run deployment
    runs-on: ubuntu-latest
    timeout-minutes: 10
    steps:
      # Checkout code
      - name: Checkout repository
        uses: actions/checkout@v2
      
      # Deploy chart
      - name: Helm chart deployment
        uses: bryk-io/chart-deploy-action@master
        with:
          name: ${{ github.event.inputs.deployment }}
          namespace: ${{ github.event.inputs.namespace }}
          version: ${{ github.event.inputs.version }}
        env:
          # Use the name space as prefix to load the required secrets
          KUBECTL_CONFIG: ${{ secrets[format('kubectl_config_{0}', github.event.inputs.namespace)] }}
          CHART_VALUES: ${{ secrets[format('chart_values_{0}', github.event.inputs.namespace)] }}
```

To manually trigger this workflow using GitHub's CLI tool.

```shell
gh workflow run deploy -f deployment=echo-server -f namespace=dev
```
