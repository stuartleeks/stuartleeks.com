---
type: post
title: "Working With Pull Requests in Azure Devops"
date: 2020-01-17T13:16:36Z
description: "Work with Azure DevOps pull requests from the command line"
draft: false
categories:
 - technical
 - tips-and-tricks
tags:
 - azure-devops
 - pull-requests
 - tips-and-tricks
---

I like working at the terminal. No judgement if you don't, but for me the terminal feels like a comfortable and productive place :-)

I also like to find ways to gradually improve my experience with the termina, and a while back I mentioned to [Lawrence](https://blog.gripdev.xyz/) that I'd created some git aliases to help me easily check out pull requests on github. He immediately replied pointing me to [github.com/ldez/prm (Pull Request Manager)](https://github.com/ldez/prm) which is an awesome tool for checking out pull requests locally and working with them.

This is great for my workflow when I'm working with [GitHub](https://github.com) but I also spend time with repos on [Azure DevOps](https://azure.microsoft.com/en-us/services/devops/?nav=min). Fortunately, I discovered the [azure-devops extenion](https://docs.microsoft.com/en-us/azure/devops/cli/?view=azure-devops) for the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest).

Once installed and configured I can find and checkout PRs with `az repos pr list` and `az repos pr checkout --id <id>` as shown below.

```bash {hl_lines=[2,9]}
~/source/MyTestRepo [master]
$ az repos pr list
ID    Created     Creator                     Title                                   Status    IsDraft    Repository
----  ----------  --------------------------  --------------------------------------  --------  ---------  ------------
5137  2020-01-16  stuart.leeks@example.com    Example PR to show az repos cli usage   Active    False      MyTestRepo
5139  2020-01-17  stuart.leeks@example.com    Another PR for demoing                  Active    False      MyTestRepo

~/source/MyTestRepo [master]
$ az repos pr checkout --id 5137  # Note the 5137 ID above

From vs-ssh.visualstudio.com:v3/example/SampleProject/MyTestRepo
 * branch            sl/example -> FETCH_HEAD
Branch 'sl/example' set up to track remote branch 'sl/example' from 'origin'.
Switched to a new branch 'sl/example'
From vs-ssh.visualstudio.com:v3/example/SampleProject/MyTestRepo
 * branch            sl/example -> FETCH_HEAD
Already up to date.

~/source/MyTestRepo [sl/example]
$

```
