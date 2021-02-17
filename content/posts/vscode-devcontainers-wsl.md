---
type: post
title: "Visual Studio Code and Devcontainers in the Windows Subsystem for Linux (WSL)"
subtitle: ""
date: 2020-04-01T19:18:23+0100
lastMod: 2020-04-08T20:47:10+0100
draft: false
categories:
 - technical
tags:
 - vscode
 - containers
 - devcontainers
 - WSL
---

> UPDATE (2020-04-08): With the [1.44 release](https://code.visualstudio.com/updates/v1_44) of Visual Studio Code (and the corresponding [Remote Containers release](https://github.com/microsoft/vscode-docs/blob/master/remote-release-notes/v1_44.md)), the Insiders release is no longer needed as the . I have updated the post to reflect this (update made in vscode devcontainer on stable release 😁).

## Introduction

In my [previous post]({{< relref vscode-devcontainers.md >}}) I gave some thoughts on using Visual Studio Code [devcontainers](https://code.visualstudio.com/docs/remote/containers). Until very recently your source code needed to be cloned in Windows in order to be able to build and run devcontainers with Visual Studio Code. While this has still been a great experience overall, I have hit a few edge cases where being able to have my source code in Linux (under WSL) and then create a devcontainer from there would have been a big help.

This is something that I've wanted to be able to do for a while and after some discussions with the Remote-Containers team (thanks [Christof](https://twitter.com/christof_marti) and [Chuck](https://twitter.com/Chuxel)!) they merged in a PR I opened that gives a starting point for this capability. In this post I'll walk through the various components that need to be configured to enable this.

## Getting set up

To get all of this working you need to have [WSL 2](https://docs.microsoft.com/en-us/windows/wsl/wsl2-index). ~~This is currently only available via the Windows Insider program - see the docs for [WSL 2 installation instructions](https://docs.microsoft.com/en-us/windows/wsl/wsl2-install).~~

To run containers on Windows you would normally install Docker for Windows. Docker for Windows used to starts up a Linux VM to run the Docker daemon in, but there is now support for [running the daemon in WSL2](https://docs.docker.com/docker-for-windows/wsl/) - open settings and ensure that the WSL integration is turned on and enabled for any WSL distributions that you want to run your devcontainers in.

![Screenshot showing the WSL integration enabled in Docker for Windows](docker-for-windows-wsl-integration.png)

Next we need Visual Studio Code and the Remote Containers extension. Get [Visual Studio Code here](https://code.visualstudio.com/Download) and then make sure you have the [Remote Extension Pack](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack) extension installed.

Finally, the WSL integration is currently in experimental mode so it isn't enabled by default. In the command palette (`Ctrl + Shift + P` by default) type `user settings` and hit Enter to load the user settings. In the settings search bar type `experimental WSL` and tick the box to enable the option.

![Screenshot showing navigating to the experimental WSL setting in VS Code](vscode-experimental-wsl.png)

> If you prefer to control your settings in JSON then the setting to add is `"remote.containers.experimentalWSL": true`

## Giving it a spin

Now that everything is installed, let's clone a sample project to give it a spin. There are a number of sample projects [listed here](https://code.visualstudio.com/docs/remote/containers#_quick-start-try-a-dev-container) such as <https://github.com/Microsoft/vscode-remote-try-python>.

Run bash (e.g `Win+R` and `bash`), navigate to a folder where you want to clone the source code and run `git clone https://github.com/Microsoft/vscode-remote-try-python`.

To load this in VS Code and be able to work on it in a devcontainer we can load the code from the bash prompt via `code .`.

Once VS Code has loaded the workspace and extensions you should get a toast notification prompting you to reopen the folder as a devcontainer. (If you don't get the prompt then select "Remote-Containers: Reopen in Container" in the command palette). Click this to reopen the folder in a devcontainer.

![Screenshot showing the VS Code prompt to reopen in container](vscode-reopen-in-container.png)

VS Code will start building the devcontainer and once that is done you will have the folder loaded in a devcontainer with the source from WSL :-)

The left side of the status bar has a handy indicator that you are running in a devcontainer

![](vscode-status-bar.png)


## Lots of preview bits

When originally written, the steps in this post used a lot of preview features but now they are all generally available and I realise that this might not be for everyone!

## Summary

Whilst it is currently early days for the WSL/devcontainers integration, I'm excited to see it coming. I'm a huge fan of devcontainers but have hit a few edge cases with them. One area is around mounting the Windows file system into a Linux container. To do this the file access has to go through a translation layer; one side effect of this is reduced performance. One repo I tried working with in a devcontainer took around 10 seconds to display the terminal prompt each time you hit Enter because it had [bash-git-prompt](https://github.com/magicmonty/bash-git-prompt) and calling out to `git status` took a long time as a result of the file system translation. Adding the ability to use devcontainers with code in WSL removes these issues as the volume being mounted in the container is already a Linux file system.

It's early days, but I'm excited to see where this goes 😁.


P.S. If you liked this, you may also like my book "WSL 2: Tips, Tricks and Techniques" which covers tips for working with WSL 2, Windows Terminal, VS Code dev containers and more <https://wsl.tips/book> :-)
