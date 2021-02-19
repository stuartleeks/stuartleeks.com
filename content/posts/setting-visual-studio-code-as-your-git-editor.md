---
type: post
title: "Setting Visual Studio Code As Your Git Editor"
date: 2020-01-22T07:17:34Z
draft: false
description: "Do you use VS Code as your editor? Make life easy on yourself for git operations by making it your git editor, too"
categories:
 - technical
 - tips-and-tricks
tags:
 - git
 - vscode
 - tips-and-tricks
---

My [last post]({{< relref working-with-pull-requests-in-azure-devops.md >}}) seemed to go down quite well, so I'm going to try a few mini-posts with a ['tips-and-tricks'](/tags/tips-and-tricks) theme. This works well for me as I'd started making some notes about productivity tips I use as part of my prep for an internal no-prep presentation ;-)

This one is a really small tip that is covered in the [Visual Studio Code docs](https://code.visualstudio.com/Docs/editor/versioncontrol#_vs-code-as-git-editor), but lots of people using Visual Studio Code seem to have missed it so I'm going to mention it here: you can set Visual Studio Code to be your git editor. To do this run:

```bash
git config --global core.editor "code --wait"
```

As the docs point out, once you have done this you can run `git config --global --edit` to add the following sections to your git config:

```config
[diff]
    tool = default-difftool
[difftool "default-difftool"]
    cmd = code --wait --diff $LOCAL $REMOTE
```

Once you've done this you will now use Visual Studio Code as the editor whenever git prompts you for commit messages, actions to take on rebase, etc.
