---
type: post
title: "Forwarding copy to clipboard from dev container to Windows Host"
date: 2021-02-17T19:11:12Z
pageSummary: "Make magic happen! Learn how to automatically forward content copied to the clipboard in a VS Code dev container to your Windows clipboard"
description: "Learn how to automatically forward content copied to the clipboard in a VS Code dev container to your Windows clipboard"
draft: false
categories:
 - technical
 - tips-and-tricks
tags:
 - wsl
 - dev-containers
 - tips-and-tricks
---



## Background

I've mentioned [VS Code dev containers]({{< relref vscode-devcontainers >}}) on this blog before and like [using them from WSL]({{< relref vscode-devcontainers-wsl>}}).

I'm also a fan of [azbrowse](https://github.com/lawrencegripper/azbrowse) for working with Azure resources from the terminal, and lately have found myself running azbrowse from within a dev container for various reasons.

There are several features in azbrowse that copy data to the clipboard, and when run from WSL it detects that and copies to the Windows clipboard, which is convenient. When run from a dev container, the experience isn't so good (a polite way of saying that it doesn't work).

In this post I'll take a tour through the setup I am using to enable applications running in dev containers to copy content onto my Windows clipboard. If you just want the final code then skip to the end, otherwise keep reading...

## Pre-requisites

Before we dive in, this post assumes that you have:
- [WSL 2](https://docs.microsoft.com/en-us/windows/wsl/wsl2-install)
- [Docker Desktop for Windows configured for WSL 2 integration](https://docs.docker.com/docker-for-windows/wsl/)
- [Visual Studio Code (VS Code)](https://code.visualstudio.com)
- [VS Code Remote-Containers extension](https://code.visualstudio.com/docs/remote/containers)

## Copying to the clipboard from WSL

Windows has shipped a utility called [clip.exe](https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/clip) for a long time. It's a handy little utility that reads from stdin and copies the contents to the clipboard. For example, running the following snippet in PowerShell will copy `Hello` to your clipboard:

```powershell
echo "Hello" | clip.exe
```

Even better, WSL 2 (by default) allows us to call Windows apps from within WSL. So, running the following snippet in bash will copy `Hello from bash` to your Windows clipboard *from inside WSL*:

```powershell
echo "Hello from bash" | clip.exe
```

## Copying to the clipboard from a container

Now that we have a way to write to the clipboard, we need a way to invoke it from a dev container. The first part of this is to have something listening in WSL and forwarding on to `clip.exe`. For this, we can use `socat` (run `sudo apt install socat` if you don't have it installed). There are many options to choose from with `socat`, but here we will instruct it to listen on a TCP port and execute `clip.exe` passing the incoming traffic. Run the following in bash:

```bash
socat tcp-listen:8121,fork,bind=0.0.0.0 EXEC:'clip.exe'
```

In this example, `socat` is listening on port `8121` (I have no real reason for picking this port - change it as you see fit!).

With `socat` listening on a TCP port, the next step is to send it some text via TCP and we can make use of `socat` again. Run the following command in another bash window:


```bash
echo "hello via socat" | socat - tcp:localhost:8121
```

This command pipes `hello via scoat` into the `socat` command to send it via TCP. The previous `socat` command is listening and forwards the text to `clip.exe` resulting in `hello via socat` being placed onto your Windows clipboard.

Since the goal is to enable copying to the clipboard from a VS Code dev container, the next step is to test in a container. With the `socat` listener still running, Run the following command to launch an ubuntu container:

```bash
docker run --rm -it ubuntu bash
```

Next, install `socat` in the container and run a slight variation of the `socat` command to send a value to the listener:

```bash
apt-get update && apt install -y socat
echo "hello from a container" | socat - tcp:host.docker.internal:8121
```

In this example, we use the [host.docker.internal](https://docs.docker.com/docker-for-windows/networking/#i-want-to-connect-from-a-container-to-a-service-on-the-host) address in the container, which is a special domain name that Docker Desktop for Windows sets up, and which maps to the IP address for the host. This provides us a way to communicate back to the `socat` listener we have running, and after running the last snippet in the docker container you will have `hello from a container` on your Windows clipboard!


## Faking xclip/xsel

As cool as it is to be able to send data from a container to the Windows clipboard with a custom command, the goal is to redirect content that applications in a container write to the clipboard so that it ends up on the Windows clipboard. 

For this step I took inspiration from [this repo](https://github.com/Konfekt/xclip-xsel-WSL) which fakes out `xsel`/`xclip` - commonly used utilities for putting text on the clipboard. 


To set up the content for this section, run the following in the container:

```bash 
mkdir /cliptest
cd /cliptest
echo -e "for i in \"\$@\"\ndo\n  case \"\$i\" in\n  (-i|--input|-in)\n    tee <&0 | socat - tcp:host.docker.internal:8121\n    exit 0\n    ;;\n  esac\ndone" > clip.sh
chmod +x clip.sh
ln -s clip.sh xsel
ln -s clip.sh xclip
export PATH=/cliptest:$PATH
```

The above snippet creates `/cliptest/clip.sh` with the following content (and makes it executable):

```bash
for i in "$@"
do
  case "$i" in
  (-i|--input|-in)
    tee <&0 | socat - tcp:host.docker.internal:8121
    exit 0
    ;;
  esac
done
```

When this script is run, it checks for the `-i`/`--input`/`-in` flags that are used with `xsel`/`xclip` to specify input to copy to the clipboard. If it finds them then it copies the input to `socat` as in our previous example (to send to the `socat` listener).

You can test that this is working by running the following in the container:

```bash
echo "hello from clip.sh" | ./clip.sh -i
```

The earlier snippet that created `clip.sh` also created symbolic links to it named `xsel` and `xclip`. It also added the folder that these symlinks are in to the `PATH`, so that running the following command will copy `hello from fake xsel` to the Windows clipboard from inside the container.

```bash
echo "hello from fake xsel" | xsel --input
```

With the fake implementation in place, any process using `xsel`/`xclip` to copy content to the clipboard from within the container will actually be sending it via our `socat` relay to the Windows clipboard!

Now all that remains is to make sure that any dev containers you run have the fake `xsel`/`xclip` installed...

## Automagic installation in a dev container

There's a handy feature in dev containers that supports [dotfiles repositories](https://code.visualstudio.com/docs/remote/containers#_personalizing-with-dotfile-repositories). With this dotfiles support, you can configure VS Code so that whenever it builds a dev container, it clones your repository inside it and runs a script from it.

We can use this to have a repository with the `clip.sh` script and symbolic links, and scripts to add update the `PATH` in `.bashrc`.

## Final solution

So, to put all this together we need to do two things:
- update the host to launch the `socat` listener
- configure VS Code to clone and use the dotfiles repo

### Launching the `socat` listener

To set up the `socat` listener in WSL, add the following to your `~/.bashrc` file:

```bash
if [[ $(command -v socat > /dev/null; echo $?) == 0 ]]; then
    # Start up the socat forwarder to clip.exe
    ALREADY_RUNNING=$(ps -auxww | grep -q "[l]isten:8121"; echo $?)
    if [[ $ALREADY_RUNNING != "0" ]]; then
        echo "Starting clipboard relay..."
        (setsid socat tcp-listen:8121,fork,bind=0.0.0.0 EXEC:'clip.exe' &) > /dev/null 2>&1 
    else
        echo "Clipboard relay already running"
    fi
fi
```

This snippet has some additional checks and configuration compared to the earlier example (such as using `setsid`). For details on this, see the post on [Forwarding SSH Agent requests from WSL to Windows]({{< relref wsl-ssh-key-forward-to-windows >}}) which covers the same steps for ensuring that the listener continues running etc.


### Configuring VS Code dev container to use dotfiles 

To automatically add the clipboard support when a dev container is built, configure the [dotfiles repositories](https://code.visualstudio.com/docs/remote/containers#_personalizing-with-dotfile-repositories) to be https://github.com/stuartleeks/wsl-dev-container-clipboard-dotfiles (or add the example code there to your own dotfiles repository).

If you are configuring via the VS Code "Prefernces: Open Settings (JSON)" command, the following configuration options will configure the dotfiles using the example repo:

```json
    "remote.containers.dotfiles.installCommand": "~/dotfiles/install.sh",
    "remote.containers.dotfiles.repository": "https://github.com/stuartleeks/wsl-dev-container-clipboard-dotfiles",
    "remote.containers.dotfiles.targetPath": "~/dotfiles",
```

## Conclusion

That's all for this time! I hope you found it useful and/or interesting, whether as a solution or as a starting point. This solution works well for me, but take it and customise it to suit you. Or just take the techniques and use them for something altogether different 😃.


*P.S. If you liked this, you may also like my book "WSL 2: Tips, Tricks and Techniques" which covers tips for working with WSL 2, Windows Terminal, VS Code dev containers and more <https://wsl.tips/book> :-)*
