---
type: post
title: "Fixing Clock Skew with WSL 2"
date: 2020-04-23T22:27:16+0100
draft: true
categories:
 - technical
tags:
 - wsl
 - powershell
---

## Background to the problem

I'm quite a fan of the Windows Subsystem for Linux (WSL), especially WSL version 2 which addresses a bunch of feedback I had for WSL 1. (There's even a link to a recording of a lightning talk I gave on WSL 2 on the [speaking notes](https://stuartleeks.com/about/writing-and-speaking#december-2019---net-oxford---wsl2) page).

However, there's one issue that continues to bite me: clock skew. With WSL 2 there's a special VM that Linux runs in that has a bunch of magic sauce applied to make it meld into the Windows environment in ways that a standard VM simply can't/doesn't (can you tell that I'm not in the WSL engineering team from that description? 😉). My understanding of the issue is that the clock skew happens when the host machine sleeps/hibernates because the VM for the WSL Linux distro doesn't have its clock updated when the host resumes.

If you want to skip straight to the workaround for this issue then head to <https://github.com/stuartleeks/wsl-clock> and follow the installation instructions.

If you're interested in how it works then keep reading...

## What I had been doing (aka the manual workaround)

The manual workaround for this is to run `sudo hwclock -s` in the VM. I've been doing this for long enough that I wrapped it in a `resetclock.sh` script so that I could get tab completion rather than typing it myself (or relying on it being in my bash history).

## What's new?

In my experience many of the best (most fun?) ideas come from random conversations with people. In this case I read a [tweet from Noel Bundick](https://twitter.com/acanthamoeba/status/1252840371358273536) that sparked something in my head. A little while later [wsl-clock](https://github.com/stuartleeks/wsl-clock) was born.

There were a bunch of thoughts that went through my head but any attempt to describe them here would lead to imposing an order and impression of logical thought process that would be nothing more than a flattering fabrication.

The general questions that I was left with as a result were:

* can I run the `hwclock` command via WSL as `root` from the Windows side?
* can I trigger a task when the host resumes from sleep/hibernation?

The first of these questions proved simple to test. The `wsl` command allows you to run commands under WSL (as well as controlling WSL). One of the parameters you can pass is `-u` for the user. Running `wsl -u root sh -C "hwclock -S"` worked!

For the second part, I discovered that the Windows Task Scheduler allows you to run a task [when a specific system event occurs](https://docs.microsoft.com/en-us/windows/win32/taskschd/task-scheduler-start-page). That certainly seemed like the sort of thing I was looking for. After putting the machine into sleep and hibernation I checked the Windows Event Log. In the System log I saw events from the `Kernel-Power` source with IDs of `107` and `507` and from what I can tell triggering on these two events seems to cover the requirement.

![Event Log showing Event IDs 107 and 507](eventlog.png)

## Creating the update script

Having convinced myself that this was looking viable I created the script to perform the `hwclock` update:

```powershell {linenos=true}
function Log($message) {
    $output = (Get-Date).ToUniversalTime().ToString("u") + "`t$message"
    Add-Content -Path "~/.wsl-clock.log" -Value $output
}

Log "********************************"
Log "*** Update WSL clock starting..."

$runningDistroCount = wsl --list --running --quiet |
        Where-Object {$_ -ne ""} |
        Measure-Object |
        Select-Object -ExpandProperty Count

if ($runningDistroCount -eq 0){
    Log "No Distros - quitting"
    exit 0
}

$originalDate=wsl sh -c "date -Iseconds"

Log "Performing reset..."
$result = wsl -u root sh -c "hwclock -s" 2>&1
$success = $?
if (-not $success){
    Log "reset failed:"
    Log $result
    exit 2
} else {
    $newDate=wsl bash -c "date -Iseconds"
    Log "clock reset"
    Log "OriginalDate:$originalDate"
    Log "NewDate:     $newDate"
    exit 0
}
```

It's not a particularly long script but there are a few points to call out.

Firstly, there's a simple logging function that outputs timestamp-prefixed messages. If you need to check whether the script is working, this log file (`.wsl-clock.log` in your Windows user folder) is the place to look.

If there are no running distros then there is no WSL clock running to be out of sync, so the script just exits. Without this we'd end up starting a distro for no reason.

Lastly, it captures the WSL date/time before and after running the clock reset. In my experience the script takes 2-3 seconds to run so any difference in the before/after times greater than this is an indication that the script has fixed clock skew!

## Creating the scheduled task

With the script ready, the final part was to schedule it to run on the resume events. It turns out that Event Viewer has a handy shortcut for this if you right-click on an event:

![Creating a scheduled task from Event Viewer](eventlog-create-task.png)

However, since I wanted to trigger on a couple of events, I created the event via the Scheduled Tasks UI (quick way to get there is `Win+R` and type `control schedtasks`). Clicking on the "Create Task" option brings up the task creation UI. On the Triggers tab I clicked "New Trigger" and then picked the option for "on an event":

![Select Event Trigger in Task Scheduler](schedtask-new-trigger.png)

From here the Basic option allows you to specify a single event, so I switched to Custom which allows you to specify a full event filter which makes it easy to select the Event Source and Event IDs that we're interested in:

![Define event filter in Task Scheduler](schedtask-event-filter.png)

With that we can set the action to run powershell and execute the clock reset script!

## Giving it a spin

In the [source code on GitHub](https://github.com/stuartleeks/wsl-clock), I've created a powershell script to create the scheduled task for you which sets up the task action to run the update clock script in a hidden window so that there's no flash of a console window.

If you want to give it a spin (please note that this is not a supported workaround!) then head to the [GitHub repo](https://github.com/stuartleeks/wsl-clock) to clone it and run the install script!