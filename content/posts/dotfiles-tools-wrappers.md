---
type: post
title: "dotfiles tools wrappers"
subtitle: ""
date: 2022-08-27T21:45:01+0100
draft: false
categories:
 - technical
tags:
 - bash
 - dotfiles
 - vscode
 - dev-containers
---

I'm a self-confessed fan of Visual Studio Code's [dev container](https://code.visualstudio.com/docs/remote/containers) experience and have a [number of posts about them](/tags/dev-containers/) including a [list of some of my favourite things with dev containers]({{< relref vscode-devcontainers.md >}}).
I find it productive to be able to capture the pre-requisites for working with a project programmatically, and share it with others working on the project.
However, there's a feature of dev containers that I use heavily which has the potential to break this model: dotfiles.

The [dotfiles support](https://code.visualstudio.com/docs/remote/containers#_personalizing-with-dotfile-repositories) in dev containers allows you to specify a dotfiles repo that VS Code will clone and install as part of the dev container build & startup.
This allows you to do this such as configure your shell prompt, configure aliases, install extra tools, or whatever else your imagination conjures up!

I find that this feature allows me to make the experience in the dev container feel comfortable to me.
For example, I started out on a [BBC micro model B](https://en.wikipedia.org/wiki/BBC_Micro) (and then DOS) where `cls` was the command to clear the screen and that muscle memory means that typing `clear` still requires concentration, so I have an alias for `cls`.

Along with my aliases, I also install a few tools that I generally like to have around, such as `jq` and `dig`.
Installing these tools is useful for times when I'm poking around on something trying to debug it, but it's also the source of the potential problem: if these tools aren't specified in the dev container them only I will have them available to me.
So if I create a script for use in the project and make use of one of these tools then it will work for me but no-one else!
As I commented in [another post](https://stuartleeks.com/posts/vscode-devcontainers/#dotfiles-and-user-extensions):

> "This is an area to exercise caution. It is important to be mindful of what customisations you apply with this to ensure that they are not things that should be part of the core dev container experience"

Since writing that comment, I've done a pretty good job of being careful, but it remained an aspect of dotfiles that was niggling at me.
I eventually got some time to play around with addressing that niggle, and in this post, I will walk through the approach I've taken with my dotfiles to try to reduce the chances of accidentally using a dotfiles-installed tool in a script.

## The Initial Idea

My first thought was to create an alias for each tool installed and have the alias point to a `wrapper.sh`.
The `wrapper.sh` script took the tool/command as the first argument and then remaining arguments that should be passed to the command.
When run, the script output a warning message and then called on to the tool.

```bash
# wrapper.sh
tool_command=$1
shift
echo "**** Using $tool_command ****"
$tool_command $@
```

With the script in place, I created an alias. For example, to wrap the `jq` command, I used the following: `alias jq=~/dotfiles/wrapper.sh jq`. Any additional arguments passed to the `jq` alias are passed to the wrapper script which passes them on to the real `jq`.

Having hacked this together, I gave it a test from my bash prompt and it worked - the script output a warning and then called `jq` passing the extra arguments along.
With hindsight, the fact that the script worked aat this point _might_ have started alarm bells ringing, but we'll come back to that shortly.

My next test was to create a bash script that called `jq` and test that the wrapper approach still worked there.

Narrator: it didn't.

When running bash scripts, you _can_ have them load aliases by adding `shopt -s expand_aliases`, but if I have to add that to my scripts to get a warning when I use a tool that's not installed by the dev container then... well, it's not really a solution!

> Side note... when the interactive test for this ran successfully earlier, if the `wrapper.sh` script had been respecting the aliases it would have created an infinite loop as the script calls the command that was being aliased


## The Revised Idea

Undeterred, I came up with a Plan B.
Instead of aliasing the commands I want to wrap, I opted to create a script file for each command that is wrapped giving it the same name as the wrapped command.
This script file outputs the warning and then invokes the original command.

The full script can be found [here](https://github.com/stuartleeks/dotfiles/blob/1ca2018e8a7ef4b9dc07eb827289468fb18fb3a9/devcontainer/install-wrapper.sh), but the key aspects are shown below:

```bash
# install-wrapper.sh

# tool_command is passed to this script and is the command to wrap

# get the actual command that should be run 
original_command=$(which $tool_command)

# create the wrapper script with the same name as tool_command
cat <<EOF > $script_dir/wrappers/$tool_command
#!/bin/bash
echo -e "\033[0;30;103m** using $TOOL from dotfiles **\033[0m" >&2
$original_command \$@
EOF
chmod +x $script_dir/wrappers/$tool_command
```

When run for `jq`, the `install-wrapper.sh` generates a script file called `jq` in the `wrappers` directory with the following content:

```bash
#!/bin/bash
echo -e "\033[0;30;103m** using jq from dotfiles **\033[0m" >&2
/usr/bin/jq $@
```

With this in place, the dotfiles `load.sh` updates the `PATH` environment variable so that the `wrappers` directory is searched ahead of the real installation directories to ensure that the wrapper is used.
Success!

## The Final Touch

The solution above  works well for helping to prevent me using a tool that is installed by my dotfiles.
A warning message is output whenever a wrapped command is executed, prompting me to add that tool to the dev container definition before committing a script that makes use of it.

However, there is one final tweak to make: since I only care about preventing the use of dotfiles-installed tools when they are use in scripts, I would happily _not_ get a warning when I use such a tool interactively.

Fortunately, there is a way to achieve that... and it makes use of the mistake I made in my original attempt: aliases!

In my final `install-wrapper.sh`, I include the following extra step:

```bash
echo "alias $tool_command='$original_command'" >> $script_dir/wrappers/.aliases
```

This adds an alias for the wrapped command that directly calls the installed tool using the qualified path.
The dotfiles load script then loads these aliases from the generated `.aliases` file.

So, using a wrapped command interactively resolves to the alias, which in turn calls the installed tool directly.
When using a wrapped command in a script, the aliases aren't loaded (as we discovered in the first attempt) and the command resolution finds the wrapper script that was added to the `PATH` which outputs the warning as desired.

Mission accomplished... my interactive use of tools is unaffected, and I get a handy nudge if I'm using a tool that isn't installed by the dev container.

Happy days!
