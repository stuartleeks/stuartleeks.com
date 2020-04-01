---
type: post
title: "Visual Studio Code and Devcontainers in the Windows Subsystem for Linux (WSL)"
subtitle: ""
date: 2020-04-01T19:18:23+0100
draft: false
categories:
 - technical
tags:
 - vscode
 - containers
 - devcontainers
 - WSL
---

> NOTE at the time of writing, several of the features/components mentioned in this post are in preview, but will hopefully hit GA soon. As with all preview bits there can be rough edges so follow these steps at your own discretion!

## Introduction

In my [previous post]({{< relref vscode-devcontainers.md >}}) I gave some thoughts on using Visual Studio Code [devcontainers](https://code.visualstudio.com/docs/remote/containers). Until very recently your source code needed to be cloned in Windows in order to be able to build and run devcontainers with Visual Studio Code. While this has still been a great experience overall, I have hit a few edge cases where being able to have my source code in Linux (under WSL) and then create a devcontainer from there would have been a big help.

This is something that I've wanted to be able to do for a while and after some discussions with the Remote-Containers team (thanks [Christof](https://twitter.com/christof_marti) and [Chuck](https://twitter.com/Chuxel)!) they merged in a PR I opened that gives a starting point for this capability. In this post I'll walk through the various components that need to be configured to enable this.

## Getting set up

To get all of this working you need to have [WSL 2](https://docs.microsoft.com/en-us/windows/wsl/wsl2-index). This is currently only available via the Windows Insider program - see the docs for [WSL 2 installation instructions](https://docs.microsoft.com/en-us/windows/wsl/wsl2-install).

To run containers on Windows you would normally install Docker for Windows. Docker for Windows normally starts up a Linux VM to run the Docker daemon in, but there is now support for [running the daemon in WSL2](https://docs.docker.com/docker-for-windows/wsl-tech-preview/) - again, at the time of writing this is a preview feature. When you have installed Docker for Windows, open settings and ensure that the WSL integration is turned on and enabled for any WSL distributions that you want to run your devcontainers in.

![Screenshot showing the WSL integration enabled in Docker for Windows](docker-for-windows-wsl-integration.png)

Next we need Visual Studio Code and the Remote Containers extension. Again, we need the preview (Insiders) version of VS Code right now which can be [installed from here](https://code.visualstudio.com/insiders/).  Insiders is needed as the updated extension requires VS Code version 1.44, but hopefully that will be available in the main release very soon (check the latest version [here](https://code.visualstudio.com/updates)). When you start up VS Code, make sure you have the [Remote Extension Pack](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack) extension installed.

Finally, the WSL integration is currently in experimental mode so it isn't enabled by default. In the command palette (`Ctrl + Shift + P` by default) type `user settings` and hit Enter to load the user settings. In the settings search bar type `experimental WSL` and tick the box to enable the option.

![Screenshot showing navigating to the experimental WSL setting in VS Code](vscode-experimental-wsl.png)

> If you prefer to control your settings in JSON then the setting to add is `"remote.containers.experimentalWSL": true`

## Giving it a spin

Now that everything is installed, let's clone a sample project to give it a spin. There are a number of sample projects [listed here](https://code.visualstudio.com/docs/remote/containers#_quick-start-try-a-dev-container) such as <https://github.com/Microsoft/vscode-remote-try-python>.

Run bash (e.g `Win+R` and `bash`), navigate to a folder where you want to clone the source code and run `git clone https://github.com/Microsoft/vscode-remote-try-python`.

To load this in VS Code and be able to work on it in a devcontainer we need to load VS Code and then open the source code via the `\\wsl$\...` share that exposes the contents of the WSL file system to Windows. I believe that this is a temporary quirk that the team intend to resolve.

To to this, `cd` into the source folder and then run `wslpath -w .` (note the `.`). This will print the Windows path to the current folder using the `\\wsl$` share. Copy this to the clipboard (or run `wslpath -w . | clip.exe` to put it on the clipboard for you!) and open that path in VS Code.

Once VS Code has loaded the workspace and extensions you should get a toast notification prompting you to reopen the folder as a devcontainer. (If you don't get the prompt then select "Remote-Containers: Reopen in Container" in the command palette). Click this to reopen the folder in a devcontainer.

![Screenshot showing the VS Code prompt to reopen in container](vscode-reopen-in-container.png)

VS Code will start building the devcontainer and once that is done you will have the folder loaded in a devcontainer with the source from WSL :-)

The left side of the status bar has a handy indicator that you are running in a devcontainer

![](vscode-status-bar.png)


## Launching from bash

My usual flow for opening code is to navigate to the folder in bash or powershell and then run `code .` to launch VS Code for the current folder. Doing this from bash loads the folder via the Remote-WSL extension which unfortunately doesn't currently allow the folder to be re-opened in a devcontainer.

To work around this until this workflow is enabled I have created a couple of functions and added them to my `~/.bashrc`:

{{< gist stuartleeks 005bcdb6da319b29bc1c20a6d0a7e8a8 helpers.sh >}}

Using these opens VS Code (or VS Code Insiders) without using the Remote-WSL extension and translates the WSL path to the `\\wsl$\...` form.

For example, `wcode-insiders .` will open the current folder using the `\\wsl$\...` path in VS Code Insiders.

## Lots of preview bits

The steps in this post use a lot of preview features and I realise that this might not be for everyone!

[WSL 2 is going to be shipped in Windows 10 version 2004](https://devblogs.microsoft.com/commandline/wsl2-will-be-generally-available-in-windows-10-version-2004/) which will hopefully be released soon. Once this is released then hopefully Docker for Windows support for WSL will also come out of preview.

The dependency on VS Code Insiders for running the latest Remote-Containers extension should go away when the next VS Code release lands. Based on the previous timings, hopefully that will be in the next week or so.

Once all the pieces above come out of preview, the remaining part is the 'experimental' piece. My understanding is that the team want to allow chance for these changes to be tested by early adopters (and who can blame them wanting to add verification of my code 😉) as well as smoothing out the rough edges.

## Summary

Whilst it is currently early days for the WSL/devcontainers integration, I'm excited to see it coming. I'm a huge fan of devcontainers but have hit a few edge cases with them. One area is around mounting the Windows file system into a Linux container. To do this the file access has to go through a translation layer; one side effect of this is reduced performance. One repo I tried working with in a devcontainer took around 10 seconds to display the terminal prompt each time you hit Enter because it had [bash-git-prompt](https://github.com/magicmonty/bash-git-prompt) and calling out to `git status` took a long time as a result of the file system translation. Adding the ability to use devcontainers with code in WSL removes these issues as the volume being mounted in the container is already a Linux file system.

It's early days, but I'm excited to see where this goes 😁.
