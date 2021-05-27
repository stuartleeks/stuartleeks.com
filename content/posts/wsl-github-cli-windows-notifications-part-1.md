---
type: post
title: "Fun with WSL, GitHub CLI and Windows Notifications"
subtitle: "Part 1: wsl-notify-send as a replacement for notify-send"
date: 2021-05-27T07:10:16+0100
lastMod:  2021-05-27T07:10:16+0100
pageSummary: See how to create a replacement notify-send utility for WSL, and how to integrate that with the GitHub cli to get Windows notifications when your GitHub workflows finish
description: Create a replacement notify-send utility for WSL, and integrate it with the GitHub cli to get Windows notifications when your GitHub workflows finish
draft: false
categories:
 - technical
tags:
 - wsl
 - github
 - tips-and-tricks
---

## Introduction

I've been making use of the [GitHub CLI](https://cli.github.com/) and finding it a productive way to work with GitHub. Recently, [Lawrence Gripper](https://blog.gripdev.xyz/) shared with me a handy alias that he had set up:

```bash
alias ghrun="gh run list | grep \$(git branch --show-current) | cut -d$'\t' -f 8 | xargs gh run watch && notify-send 'Run finished'"
```

This `ghrun` alias finds the latest GitHub actions workflow for the current branch and starts a `gh run watch` for it. This shows the progress through the steps of a workflow:

![Screenshot showing gh run watch output](./gh-run-watch.png)

The final part of the alias calls `notify-send` to pop up a desktop notification when the workflow has completed (handy if the workflow takes a while and you want to avoid getting too distracted by twitter/blogs/...). When running in WSL, `notify-send` wasn't working so I initially commented that part out, but I started to want that functionality. There are various ways to add this and in the rest of this post we'll look at one of those options: creating a custom `notify-send` for WSL.

## Creating a notify-send replacement for WSL

If there were a `notify-send` implementation for WSL then I would have been able to take Lawrence's alias and use it as-is. A quick search didn't turn up anything that was quite what I was looking for, but I did find [go-toast/toast](https://github.com/go-toast/toast) which is a nice little golang package that wraps up calling the Windows APIs for sending desktop notifications.

Having discovered toast, I threw together [wsl-notify-send](https://github.com/stuartleeks/wsl-notify-send). This gives a `wsl-notify-send.exe` (Windows executable) that accepts the same set of command line arguments as the Linux `notify-send` utility. Thanks to WSL's interop with Windows, we can call `wsl-notify-send.exe` from WSL:

```bash
# Call with qualified path
/mnt/c/path/to/download/wsl-notify-send.exe "Hello from WSL"

# Or if the location is in your Windows PATH
wsl-notify-send.exe "Hello again"
```

Some of the arguments are ignored in `wsl-notify-send.exe` as they don't directly map on to the Windows notifications, but by at least accepting them, we can use it as a replacement for `noitfy-send`. There are a few ways we can achieve this:

- copy `wsl-notify-send.exe` to `notify-send` in your WSL `PATH`
- create an alias for `wsl-notify-send.exe`: `alias notify-send=wsl-notify-send.exe` (include the path if not in your Windows `PATH`)
- add bash function, e.g. `notify-send() { wsl-notify-send.exe --category "$WSL_DISTRO_NAME" "$@"; }`

Personally, I quite like the last option as it defaults the `category` to be the name of the WSL distro that I'm running in 😀.

For example, here you can see `notify-send` without `--category` and the WSL distro name is used:

![screenshot showing notification with WSL distro name](./notify-send.png)

And here you can see `--category` specified and overriding the default:

![screenshot showing notification with overridden category](./notify-send-category.png)

Whichever option you go with, you can now run scripts that use `notify-send` without needing to make updates! 

In the [next post]({{< relref "wsl-github-cli-windows-notifications-part-2/index.md" >}}) we'll take a look at what we can do by making some tweaks to `ghrun` to integrate other features of Windows notifications...

*P.S. If you liked this, you may also like my book "WSL 2: Tips, Tricks and Techniques" which covers tips for working with WSL 2, Windows Terminal, VS Code dev containers and more <https://wsl.tips/book> :-)*