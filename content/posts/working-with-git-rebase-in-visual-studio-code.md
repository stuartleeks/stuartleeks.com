---
title: "Working With Git Rebase in Visual Studio Code"
date: 2020-01-21T13:16:36Z
draft: true
categories:
 - technical
 - tips-and-tricks
tags:
 - git
 - vscode
 - tips-and-tricks
---

Following the [git theme]({{< relref setting-visual-studio-code-as-your-git-editor.md >}}) for mini-posts, I thought I'd gitve `git rebase` a mention this time.

When I first started working with git I found a way to pretend that it was a source control system like any other that I'd used. Eventually, I was working on a pull request for an OSS project and a maintainer asked me to rebase my changes. Now, I'd heard of rebase at that point but I hadn't used it, so I was a bit daunted. So this post has a few tips that I wish I'd known at that point. By way of encouragement, I'll add that getting familiar with git rebase is a huge part of the reason that I love git and has improved my developer workflow.

First up, `git rebase --help` is your friend. Seriously! It brings up local help (i.e. works offline) and is actually really good. That's not to say that it won't need a few readings - git rebase is a powerful tool, after all. But, it has a bunch of different scenarios laid out as commit graphs with the before and after states along with the commands to execute.

Secondly, when you are in the middle of a rebase you can do `git rebase --abort` and git will wind everything back to where you started. Aborting can be useful to just go back and remind yourself of the original changes so that it is easier to understand how to resolve conflicts during a rebase. I've also had a few occasions where aborting gave me an opportunity to squash together some related commits and remove some of the rebase conflicts in the process.

Also, since rebase creates new commits your old commits aren't deleted as part of the rebase and can still be accessed after completing the rebase if you want to go back. Not being deleted doesn't mean that they are easy to access; you could make a note of the commit ID, or you could just `git branch starting-point` (or some such) before the rebase and give yourself a nice easy name to refer to the original commit by. Then if you aren't happy with how the rebase went you can just `git checkout starting-point` to get back to the commit you were originally on.

One final point on the safety net theme: your code and git state are all in your source folder - if you take a copy of that folder then you have a full backup of the state of your code and commit history! It may sound a little extreme, but it definitely helped give me confidence to perform a rebase on a couple of occasions :-)

This post is starting to get a little long for a mini-post, so I'll give a shout-out to the [Git Rebase Shortcuts](https://marketplace.visualstudio.com/items?itemName=trentrand.git-rebase-shortcuts) extension for Visual Studio Code. This extension is a bit of a niche extension, but I really like it!

When you do an interactive rebase, git prompts you with a file like the one below to determine what actions you want it to take. You can change move commits around to re-order them or change `pick` to `reword`, `squash`, etc to edit commit messages or squash a commit with the previous commit (in short, re-write your history).

```git-rebase
pick abcdefg Some commit message
pick 0123456 Did some stuff
pick 0a1b2c3 Did more stuff
...
```

Moving lines around in Visual Studio Code is nice and easy with the `Alt+Up/Down` key combination. The Git Rebase Shortcuts extension makes it really quick to change `pick` to other values: all you need to do is press `r` for `reword`, `s` for `squash`, etc. Like I said, it's a niche extension, but I find it really useful for focussing on what I want the rebase to do rather than on the file editing. The [extension homepage](https://marketplace.visualstudio.com/items?itemName=trentrand.git-rebase-shortcuts) has a nice animated GIF showing it in action :-)
