---
type: post
title: "Fun with Git for Windows, SSH Keys and Passphrases"
date: 2020-06-30T14:18:36Z
draft: false
categories:
 - technical
 - tips-and-tricks
tags:
 - ssh
 - git
 - tips-and-tricks
---

Disclaimer: this post is one to file under "things I'm blogging in the hope that I find the answer more quickly next time".

## Background

I switched to using SSH key auth for GitHub and Azure DevOps Repos a long time ago and never looked back. For a while I was using SSH keys without passphrases but got round to adding passphrases a while back. I set up the Windows OpenSSH Authentication Agent - the service defaults to Disabled so I set it as Automatic start and nudged it to Running.

![Windows Services showing OpenSSH Authentication Agent Running](windows-services.png)

With the Agent running I could run `ssh-add` to add my keys (prompting me for my pass phrase). Since I have these keys [added to GitHub](https://help.github.com/en/github/authenticating-to-github/adding-a-new-ssh-key-to-your-github-account), I could [test my ssh connection to GitHub](https://help.github.com/en/github/authenticating-to-github/testing-your-ssh-connection) using `ssh -T git@github.com`. This all worked so I was happy.

I have been using WSL quite a bit recently and configured to forward SSH requests to the Windows SSH Agent (that's a topic for [another post]({{< relref wsl-ssh-key-forward-to-windows.md>}})), and the same `ssh -T git@github.com` works in WSL, too.

Since configuring this, I've been happily working with `git` in the terminal with WSL for a while. Today I wanted to work with some code that I had cloned in Windows, so ran a `git remote update` to check that I was up-to-date, but that prompted me for my passphrase. At this point I was confused: this is all working fine in WSL without prompting me, and WSL is configured to forward the SSH auth to the OpenSSH Agent in Windows!

## The explanation

After staring at the screen and retrying the command to make sure, I re-ran the `ssh -T git@github.com` command in Windows and that ran fine (without prompting me).

Cue lightbulb moment (actually there was some muttering to myself while pacing the office that preceeded this): git ships with its own ssh! (at least git for Windows does). There's a hint towards that in [these GitHub docs](https://help.github.com/en/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent#adding-your-ssh-key-to-the-ssh-agent) where they say to start Git Bash to run `ssh-add`. 

Running `Get-Command ssh.exe` in PowerShell pointed me to the OpenSSH installation at `C:\WINDOWS\System32\OpenSSH\ssh.exe`. So when I was running `ssh -T git@github.com` that was using the OpenSSH `ssh.exe` and connecting to the Open SSH Authentication Agent where I had added the keys.

When git was running SSH, it was running its own `ssh` and was blissfully unaware of the agent I had added the keys to.

## The fix

To fix this I ran `$env:GIT_SSH="C:\Windows\System32\OpenSSH\ssh.exe"` to set the `GIT_SSH` environment variable described [here](https://git-scm.com/book/en/v2/Git-Internals-Environment-Variables#_miscellaneous). Note that I ran this as a way to test that this worked, but it only sets the environment variable for that instance of PowerShell. The _real_ fix is to set this environment variable at the machine level to avoid hitting the issue again.

Re-running `git remote update` worked, without prompting me (now that it was using the SSH agent where I had configured the keys)!
