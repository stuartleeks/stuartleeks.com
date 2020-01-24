---
type: post
title: "Working With Multiple Kubernetes Contexts"
date: 2020-01-24T20:24:13Z
draft: false
categories:
 - technical
 - tips-and-tricks
 - kubernetes
tags:
 - kubernetes
 - kubectl
 - tips-and-tricks
---


If you're working with Kubernetes then there's a pretty good chance that you've been working with `kubectl`!

There's also a pretty good chance that you end up working with more than one cluster context. So, how do you manage multiple contexts?

## KUBECONFIG

One way that you might have encountered is obtaining a `kubeconfig` file that contains the details of how to connect to a cluster. `kubectl` allows you to pass a `--kubeconfig` option to commands to specify which `kubeconfig` should be used to connect to a cluster to execute the command. E.g. `kubectl get pods --kubeconfig=/path/to/kubeconfig`.

Repeatedly passing the `--kubeconfig` option can get tedious, so an alternative is to set the `KUBECONFIG` environment variable and `kubectl` will use that, e.g. `export KUBECONFIG=/path/to/kubeconfig` (bash) or `$env:KUBECONFIG=c:\path\to\kubeconfig` (PowerShell).

## Multiple KUBECONFIGs, multiple contexts

Even better, you can specify multiple contexts in the `KUBECONFIG` environment variable, e.g. `export KUBECONFIG=/path/to/kubeconfig:/path/to/another/kubeconfig`. At this point, you might be wondering how to switch between the multiple contexts when you have multiple files (or indeed if you have multiple contexts defined within a single file!).

Firstly, you can find out what contexts are currently in scope by running `kubectl config get-contexts`:

```bash
$ kubectl config get-contexts
CURRENT   NAME          CLUSTER       AUTHINFO                           NAMESPACE
          aks-dev       aks-dev       clusterUser_aks-dev_aks-dev        default
*         scale-test    scale-test    clusterUser_scale-test_scale-test  loadtest
```

Then you can change context using `kubectl config use-context <context-name>`.

> Aside: to understand the rules for how `kubectl` merges the contexts from multiple files check out [this section in the docs](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/#merging-kubeconfig-files)

## kubectx

Whilst the `kubectl config use-context <context-name>` command works, if you find yourself regularly wanting to view and change contexts then I'd highly recommend [`kubectx`](https://github.com/ahmetb/kubectx). `kubectx` is written in bash and is a hugely productive addition to your `kubectl` toolkit that lets you quickly change contexts (complete with tab completion). There is a great GIF showing it in action on the [GitHub project page](https://github.com/ahmetb/kubectx).

> As a bonus the repo also includes `kubens` which makes switching namespaces just as easy!

## Merging contexts

Another handy trick that I only discovered recently is merging multiple configs into a single file. For clusters that I expect to continue working with for a while I've found this useful to merge `kubeconfig` files into the main `~/.kube/config` file so that I don't have to keep setting the `KUBECONFIG` environment variable.

To do this I've used the following:

```bash
cp ~/.kube/config ~/.kube/config.bak && \
    KUBECONFIG=/path/to/kubeconfig:~/.kube/config.bak kubectl config view --flatten > ~/.kube/config
```

This command takes a backup of the original config and then sets up the `KUBECONFIG` environment variable to point to a new `kubeconfig` file as well as the one in my user folder. Then it executes `kubectl config view --flatten` to output the resulting merged config and redirects it to the default `kubeconfig`. For temporary clusters I don't necessarily bother with this as it bloats my `kubeconfig` file, but for slightly more durable clusters it has proved very convenient!
