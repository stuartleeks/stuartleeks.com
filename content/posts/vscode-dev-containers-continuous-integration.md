---
type: post
title: VS Code Dev Containers and Continuous Integration
subtitle: Reusing your dev container in GitHub Workflows
date: 2021-07-08T20:21:12Z
draft: false
pageSummary: "Reusing your dev container in GitHub Workflows"
description: "Reusing your dev container in GitHub Workflows"
categories:
 - technical
 - tips-and-tricks
tags:
 - dev-containers
 - github
---



## Background

Visual Studio Code has a cool feature called [dev containers](https://code.visualstudio.com/docs/remote/containers) and I've [got a number of posts about them](/tags/dev-containers/) (and even included a chapter on them in my [book on Windows Subystem for Linux (WSL)](https://wsl.tips/book)).

Dev containers allow you to encapsulate the tools/dependencies that your project needs in a container image meaning you can replace the README steps for tool installation that you'd have to manually work through with a `Dockerfile` that automates it. This makes it much quicker to onboard someone to your project, ensures consistent tooling across the team, and isolates tools in the container making it easier to work with different versions of tools across different projects.

This container image contains the tools needed to build your project, so as well as using it for local development, there are benefits to using it for your continuous integration builds: your automated builds will use the same tools and versions that you are developing with locally. Additionally, if you add a new tool to the container or update a tool version, your continuous integration environment will get the same change automatically.

To do this, you can set up your continuous integration builds to execute the `docker build` command to build your dev container image from your `Dockerfile`, and then use `docker run` to execute your build scripts in a container from that image. In fact, this is the approach that I've taken on a number of projects, but there are a number of things that Visual Studio Code allows you to configure for your your local development that you have to replicate in your continuous integration environment. As a result of this, I created the [`devcontainer-build-run` project](https://github.com/stuartleeks/devcontainer-build-run#devcontainer-build-run). The is an early project with the aim of simplifying the re-use of dev containers in continuous integration and supports GitHub workflows and Azure DevOps Pipelines.


## Setting up continuous integration with a dev container

This section will walk through setting up a [GitHub workflow with devcontainer-build-run](https://github.com/stuartleeks/devcontainer-build-run/blob/main/docs/github-action.md), but if you are interested in using Azure DevOps Pipelines then see [these docs](https://github.com/stuartleeks/devcontainer-build-run/blob/main/docs/azure-devops-task.md).

If you are new to GitHub workflows, then it is worth taking a few moments to read the [introductory guide](https://docs.github.com/en/actions/learn-github-actions).

### Get your code

A common starting point for a workflow is the `actions/checkout` action - this gets the relevant source code on the build agent.

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:

      - name: Checkout (GitHub)
        uses: actions/checkout@v2
```

### Set up Docker BuildKit

Before we use the devcontainer-build-run action, there are a couple of things to set up. The first is to set up [Docker BuildKit](https://docs.docker.com/develop/develop-images/build_enhancements/), which is what devcontainer-build-run will use to build the container image:

```yaml
      - name: Set up Docker BuildKit
        uses: docker/setup-buildx-action@v1
```

### Sign in to container registry

Once we have BuildKit enabled, the next thing to do is to log in to the container registry where you would like to save your dev container images. This is optional (you can disable pushing images by setting `push: never` on the devcontainer-build-run action), but pushing your image to the registry allows later builds to re-use the previously built image rather than rebuilding it which speeds up the builds. (By default, the action will only push the container images on builds that are triggered by pushes but this can be [overridden as per the documentation](https://github.com/stuartleeks/devcontainer-build-run/blob/main/docs/github-action.md))

Conveniently, GitHub provides us with a [built-in container registry](https://github.com/stuartleeks/devcontainer-build-run/blob/main/docs/github-action.md) and we can log in to it using the `docker/login-action` action:

```yaml
      - name: Login to GitHub Container Registry
        uses: docker/login-action@v1 
        with:
          registry: ghcr.io
          username: ${{ github.repository_owner }}
          password: ${{ secrets.GITHUB_TOKEN }}
```

### Build and run the dev container

With this in place, we can now drop in the devcontainer-build-run action:

```yaml
      - name: Build and run dev container task
        uses: stuartleeks/devcontainer-build-run@v0.1
        with:
          # Change this to point to your image name
          imageName: ghcr.io/example/example-devcontainer
          # Change this to be your CI task/script
          runCmd: make ci-build
```

The `imageName` is the name of the image to build the dev container as, and needs to include the registry prefix (`ghcr.io` in this case) if you want to push the image to a registry.

The `runCmd` is the command to run inside the dev container image once it is built. I typically have a `Makefile` target or a CI script to run, but you can also specify multiple commands as shown below:

```yaml
      - name: Build and run dev container task
        uses: stuartleeks/devcontainer-build-run@v0.1
        with:
          imageName: ghcr.io/example/example-devcontainer
          runCmd: |
            echo "Hello"
            echo "Hello again"
```

The complete workflow YAML is shown below:

```yaml
name: 'build' 
on: # rebuild any PRs and main branch changes
  pull_request:
  push:
    branches:
      - main

jobs:
  build:
    runs-on: ubuntu-latest
    steps:

      - name: Checkout (GitHub)
        uses: actions/checkout@v2

      - name: Set up Docker BuildKit
        uses: docker/setup-buildx-action@v1

      - name: Login to GitHub Container Registry
        uses: docker/login-action@v1 
        with:
          registry: ghcr.io
          username: ${{ github.repository_owner }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build and run dev container task
        uses: stuartleeks/devcontainer-build-run@v0.1
        with:
          # Change this to point to your image name
          imageName: ghcr.io/example/example-devcontainer
          # Change this to be your CI task/script
          runCmd: make ci-build
```

With this workflow, your continuous integration builds will build the dev container image and run the `make ci-build` step inside an instance of that container. For successful builds of merges to the `main` branch, the dev container image will be pushed to the container registry. 

When a container image is built from a `Dockerfile`, each step creates 'layer'. Providing none of the files for a step have changed, subsequent builds can re-use layers rather than recreating them to improve build speeds. Normally, this layer cache resides on the machine that built the image, but with Docker BuildKit these cached layers can also come from an image in a registry. So by pushing the dev container image to a registry, the image will be used as a layer cache for future builds even if that happens on a different machine (as is the case with hosted runners). This helps to reduce the time taken to build the dev container image.

As well as providing a way to use cached images, the devcontainer-build-run action also does a few other things to try to give a smoother experience such as setting the working directory to be the workspace folder (i.e. the same as the default folder in Visual Studio Code) and adding in container mounts that are specified in `devcontainer.json` (handy if you are using docker-from-docker to mount the `/var/run/docker.sock` from the host into the container). It also checks if you have specified a user in `devcontainer.json` and runs the command under that user (after ensuring that the UID/GID for that user match the user on the host - also handy for docker-from-docker).

With this in place, we can take the dev container definition that we use for local development with Visual Studio Code and re-use that environment for continuous integration builds.

## Bonus - speeding up local dev container image builds

With our continuous integration builds creating and pushing the dev container image to a container registry, we can take advantage of a new feature in dev containers... [the `cacheFrom` setting](https://github.com/microsoft/vscode-docs/blob/main/remote-release-notes/v1_58.md#devcontainerjson-support-for---cachefrom). 

In the same way that the continous integration builds can use the images in the container registry as a layer cache to speed up building the image, the `cacheFrom` setting in `devcontainer.json` allows us to tell Visual Studio Code what image to use as a cache:

```json
{

 "build": {
    "dockerfile": "Dockerfile",
    "cacheFrom": "ghcr.io/example/example-devcontainer"
  }

}
```

With `cacheFrom` specified, the dev container logs will now show the following output indicating that the cache metadata is being pulled from the registry (this is small and lets BuildKit determine which layers are suitable for use as caches):

```
=> importing cache manifest from ghcr.io/stuartleeks/devcontainer-build-  0.1s
```

Then the build proceeds and uses the layers from the registry image, as indicated by the `CACHED` prefixes on the build steps followed by the steps to pull those layers from the registry:

```
 => [1/9] FROM mcr.microsoft.com/vscode/devcontainers/base:debian-10@sha2  0.0s
 => [internal] load build context                                          0.0s
 => => transferring context: 110B                                          0.0s
 => CACHED [2/9] RUN mkdir -p ~/.local/bin                                 0.0s
 => CACHED [3/9] RUN sudo apt-get update     && sudo apt-get -y install -  0.0s
 => CACHED [4/9] RUN echo "export HISTFILE=/home/vscode/commandhistory/.b  0.0s
 => CACHED [5/9] COPY scripts/golang.sh /tmp/                              0.0s
 => CACHED [6/9] RUN /tmp/golang.sh 1.16.5                                 0.0s
 => CACHED [7/9] RUN     go get github.com/go-delve/delve/cmd/dlv@v1.6.0   0.0s
 => CACHED [8/9] COPY scripts/docker-client.sh /tmp/                       0.0s
 => CACHED [9/9] RUN /tmp/docker-client.sh 20.10.5                         0.0s
 => => pulling sha256:07c02b07cb2f7b2c851ce4da26e1281aa7d4d01f25d6489abd3 30.9s
 => => pulling sha256:bc89512d3076c1606a76ecad603a90af80cdf38f252d25fd72d  0.6s
 => => pulling sha256:1a39a6999bede1a473bd930ff186ee48501253bd4efaf562fff  0.4s
 => => pulling sha256:5e9ab38dec088a8c885f03fec4a95576318dee3952d42bfe547  0.3s
 => => pulling sha256:6a4029af107824e9492a31fa68e1c95a6913abb76cc88338c15 40.1s
...
```


With this change in place we now have a virtuous cycle: we take the benefits of dev containers for local development and re-use the same set of tools in our continuous integration builds, and we take the dev container image from our continuous integration builds and use those to speed up the dev container image creation for our local development!

Happy 'dev container'ing!

*P.S. If you liked this, you may also like my book "WSL 2: Tips, Tricks and Techniques" which covers tips for working with WSL 2, Windows Terminal, VS Code dev containers and more <https://wsl.tips/book> :-)*
