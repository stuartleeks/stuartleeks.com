---
type: post
title: Set Windows Terminal to use your user HOME directory
description: Wish that Windows Terminal started in your user HOME directory for WSL profiles?
subtitle: ""
date: 2020-10-09T12:31:17Z
draft: false
categories:
 - technical
tags:
 - wsl
 - windows-terminal
---

> Cross-posted from [wsl.tips/tips/windows-terminal-start-directory](https://wsl.tips/tips/windows-terminal-start-directory)

[Windows Terminal](https://aka.ms/terminal) is the new Terminal experience from the Windows team. It's [open source](https://github.com/microsoft/terminal) and iterating quickly. As a WSL user, a really nice feature is that it auto-detects the WSL distros you have installed.

By default, when you launch Windows Terminal for a WSL distro it puts you in the `/mnt/...` path for your Windows user profile (e.g. `/mnt/c/Users/stuart`). 

As [this post](https://www.docker.com/blog/docker-desktop-wsl-2-best-practices/) by [Simon Ferquel](https://twitter.com/sferquel) suggests: "Fully embrace WSL2"! In other words, use the file system in your WSL distro. When you embrace this mindset, having Windows Terminal put you in a mounted Windows path is less helpful - I like to have it default to my `HOME` directory for the distro.

Fear not! This can be configured in the Windows Terminal settings. Fire up Windows Terminal and press `Ctrl+,` to open the JSON settings. For each profile you can set a `startingDirectory` property. There are two things to bear in mind for this property:

1. The path needs to be a Windows path - so for your `HOME` folder in WSL you need to use the `\\wsl$\...` file share
1. Backslashes need to be escaped, so this becomes `\\\\wsl$\\...`

To make it easy to get this path you can run the following command from your distro. This will convert the WSL `HOME` folder path to `\\wsl$\...` form, escape the backslashes and then pop the result on the clipboard ready for you to paste into your 


```bash
wslpath -w ~ | sed 's/\\/\\\\/g' | clip.exe
```


Here's an example of the finished result:

```json
"profiles": {
    "defaults": {
        // Put settings here that you want to apply to all profiles.
        // "fontFace": "OpenDyslexicMono",
        // "fontSize": 16
    },
    "list": [
        {
            "guid": "{07b52e3e-de2c-5db4-bd2d-ba144ed6c273}",
            "hidden": false,
            "name": "Ubuntu-20.04",
            "source": "Windows.Terminal.Wsl",
            "fontFace": "Cascadia Mono PL",
            "startingDirectory": "\\\\wsl$\\Ubuntu-20.04\\home\\stuart"
        },

```


Enjoy!

P.S. If you liked this, you may also like my book "WSL 2: Tips, Tricks and Techniques" which covers tips for working with WSL 2, Windows Terminal, VS Code dev containers and more <https://wsl.tips/book> :-)