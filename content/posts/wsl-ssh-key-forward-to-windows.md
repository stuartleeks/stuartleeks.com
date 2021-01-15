---
type: post
title: "Forwarding SSH Agent requests from WSL to Windows"
date: 2020-07-03T15:11:12Z
draft: false
categories:
 - technical
 - tips-and-tricks
tags:
 - wsl
 - ssh
 - git
 - tips-and-tricks
---



## Background

As I mentioned in my [previous post]({{< relref git-for-windows-ssh-key-passphrases.md >}}), I switched to using SSH key auth for GitHub and Azure DevOps Repos a long time ago and found it a positive experience. At first I was a bit lazy and didn't use passphrases on my keys, and just kept a copy of my keys in the `.ssh` folder in my User folder in Windows and another copy in `~/.ssh` in WSL. 

For day-to-day working this worked okay, but I finally got round to adding passphrases to my keys a while back and was less happy with the setup at that point. My previously suppressed niggles around having the keys in multiple places re-surfaced once I had to add handle passphrases in multiple systems on the same machine!

As it happens, recent versions of Windows ship with the OpenSSH Agent and Server but I didn't want to have two SSH Authentication services each with their own set of keys. My last post shows [how to get git in Windows to use the OpenSSH Agent]({{< relref git-for-windows-ssh-key-passphrases.md >}}) to retrieve keys. In this post, I'll walk through the journey to get SSH in WSL using keys from the Windows OpenSSH Agent. For details on installing and setting up the Windows OpenSSH Agent see [the docs](https://docs.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse).

If you just want to set up the WSL SSH forwarding then skip to the [final solution](#final-solution)! Otherwise, let me take you on a tour...

## Initial investigation

As I mentioned, my most common usage of SSH keys day-to-day is as a way to authenticate to git remotes. This lead me to [this page in the GitHub docs](https://docs.github.com/en/developers/overview/using-ssh-agent-forwarding) which discusses SSH Agent forwarding and mentions the `SSH_AUTH_SOCK` environment variable.

After some reading it turns out that `SSH_AUTH_SOCK` controls the path to the UNIX socket that is used by SSH tools to communicate with the SSH Agent. This seemed like an interesting start, and fortunately I'd previously stumbled across the [npiperelay]() from [John Starks](https://twitter.com/gigastarks). The docs and examples for `npiperelay` have some examples for using `npiperelay` with the `socat` utility as a way of forwarding Linux sockets in WSL to named pipes in Windows - sounds perfect!

## Get the tools

First off, I grabbed `socat`:

```bash
# replace with the appropriate install for non-Debian/Ubuntu distros ;-)
sudo apt install socat
```

Next up, I built `npiperelay`, but happily John merged a PR that added releases, so you can now grab the [latest release from GitHub](https://github.com/jstarks/npiperelay/releases/latest). Once downloaded, extract the `npiperelay.exe` and place it somewhere in your `PATH`.

## Exploring `npiperelay` and `socat`

The [docker-relay](https://github.com/jstarks/npiperelay/blob/master/scripts/docker-relay) example from `npiperelay` shows how to forward the `/var/run/docker.sock` socket to the `//./pipe/docker_engine` named pipe.

```bash
# Example from https://github.com/jstarks/npiperelay/blob/master/scripts/docker-relay
exec socat UNIX-LISTEN:/var/run/docker.sock,fork,group=docker,umask=007 EXEC:"npiperelay.exe -ep -s //./pipe/docker_engine",nofork
```

I took a bit of time to [read up on `socat`](https://linux.die.net/man/1/socat). My understanding of the previous command is that it listens to the `/var/run/docker.sock` UNIX socket and when it gets a connection it launches the `EXEC` command. So in this case it starts an instance of `npiperelay.exe` using the specified arguments and forwards the data received on the UNIX socket to the input stream for `npiperelay`. On the other side, `npiperelay` takes the data sent to its input stream and forwards it to the `//./pipe/docker_engine` named pipe.

In this way, `npiperelay` and `socat` combine to be a way to forward from a UNIX socket to a Windows named pipe - pretty cool!

## Testing it with `SSH_AUTH_SOCK`

Armed with new tools and knowledge, I deleted my SSH keys from `~/.ssh` in WSL and then ran the following commands to set `SSH_AUTH_SOCK` and start socat.

```bash
export SSH_AUTH_SOCK=$HOME/.ssh/agent.sock
socat UNIX-LISTEN:$SSH_AUTH_SOCK,fork EXEC:"npiperelay.exe -ei -s //./pipe/openssh-ssh-agent",nofork &
```

Once that is set up I gave it a test to authenticate with GitHub (note that I've already [added the key to GitHub and the Windows OpenSSH Agent](https://docs.github.com/en/github/authenticating-to-github/adding-a-new-ssh-key-to-your-github-account)):

```bash
$ ssh -T git@github.com
Hi stuartleeks! You've successfully authenticated, but GitHub does not provide shell access.
```

Success! 

Or almost :-)

It turns out that there are a few challenges with this, at least there are when you put it into your `.bashrc` so that it runs automatically when you start your terminal.

## Fixing up the script

In this section we'll walk through the series of tweaks that I ended up making to the script. This will help to understand the script but feel free to skip ahead to the [final solution](#final-solution) if you are keen to get this set up.

### Handling multiple instances of terminal

The first issue I hit was running multiple instances of the terminal. To overcome this I added a check via `ps -aux` to look to see if the `socat`/`npiperelay` command was running.

My first attempt at this was:

```bash
ALREADY_RUNNING=$(ps -aux | grep -q "npiperelay.exe -ei -s //./pipe/openssh-ssh-agent"; echo $?)
```

Unfortunately, this always returned `0`. Dropping the `-q` and running it interactively, I realised that the `ps... | grep...` command was being listed in the `ps` output, so it alwasy got a match. Fortunately, a colleague had pointed me to a nice way round this a while back:

```bash
ALREADY_RUNNING=$(ps -aux | grep -q "[n]piperelay.exe -ei -s //./pipe/openssh-ssh-agent"; echo $?)
```

Note the square brackets around the `n` in `[n]piperelay.exe`. That gives a regular expression that requires that character to be an `n`, so we still match the original search string for the `grep` stage. But, it changes the command so that it no longer matches itself!

With this in place, I still hit an issue where sometimes it wasn't finding the existing process. This took me a little longer to track down, but the issue was that the `ps` output gets truncated to try to fit in the terminal width. Adding the `-ww` to the `ps` command forced it to not truncate:

```bash
ALREADY_RUNNING=$(ps -auxww | grep -q "[n]piperelay.exe -ei -s //./pipe/openssh-ssh-agent"; echo $?)
```

## Clearing out previous sockets

Unfortunately, my notes for this part are missing some details, but I hit a scenario where sometimes the socket already existed. 

For this I added a test using the `-S` condition (a list of condition expressions can be found [here])http://tldp.org/LDP/Bash-Beginners-Guide/html/sect_07_01.html#tab_07_01_).

If our `socat` command isn't running then I added this check before starting it:

```bash
if [[ -S $SSH_AUTH_SOCK ]]; then
    # not expecting the socket to exist as the forwarding command isn't running (http://www.tldp.org/LDP/abs/html/fto.html)
    echo "removing previous socket..."
    rm $SSH_AUTH_SOCK
fi
```

### Keeping the forwarding running

I also wanted to keep the `socat` command running when I closed the terminal (ready for the next session). After some searching, I found [this StackOverflow question](https://stackoverflow.com/questions/19233529/run-bash-script-as-daemon) which pointed me to [setsid](https://linux.die.net/man/2/setsid).

Adding `setsid` and suppressing the output resulted in 

```bash
(setsid socat UNIX-LISTEN:$SSH_AUTH_SOCK,fork EXEC:"npiperelay.exe -ei -s //./pipe/openssh-ssh-agent",nofork &) > /dev/null 2>&1
```
At this point, it can all be put together...

## Final solution

The end result is that once `socat` is installed in WSL, and `npiperelay` is (See how to [get the tools](#get-the-tools)), you can add this script to your `~/.bashrc`.

Note that this also requires that you have set up the SSH Agent in Windows and added your keys to it (as mentioned in the [previous post]({{< relref git-for-windows-ssh-key-passphrases.md >}})).

```bash
# Configure ssh forwarding
export SSH_AUTH_SOCK=$HOME/.ssh/agent.sock
# need `ps -ww` to get non-truncated command for matching
# use square brackets to generate a regex match for the process we want but that doesn't match the grep command running it!
ALREADY_RUNNING=$(ps -auxww | grep -q "[n]piperelay.exe -ei -s //./pipe/openssh-ssh-agent"; echo $?)
if [[ $ALREADY_RUNNING != "0" ]]; then
    if [[ -S $SSH_AUTH_SOCK ]]; then
        # not expecting the socket to exist as the forwarding command isn't running (http://www.tldp.org/LDP/abs/html/fto.html)
        echo "removing previous socket..."
        rm $SSH_AUTH_SOCK
    fi
    echo "Starting SSH-Agent relay..."
    # setsid to force new session to keep running
    # set socat to listen on $SSH_AUTH_SOCK and forward to npiperelay which then forwards to openssh-ssh-agent on windows
    (setsid socat UNIX-LISTEN:$SSH_AUTH_SOCK,fork EXEC:"npiperelay.exe -ei -s //./pipe/openssh-ssh-agent",nofork &) >/dev/null 2>&1
fi
```

With all this in place your SSH keys will be handled by the Open SSH Agent in Windows and SSH in WSL will access them from there!
