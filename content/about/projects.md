---
title: "Projects and contributions"
date: 2020-01-08T16:34:05Z
draft: false
type: page
---

* [My Contributions](#my-contributions)
* [My Projects](#my-projects)

## My Contributions

In addition to creating [my own projects](#my-projects), I also enjoy contributing to other projects.

### azbrowse - an interactive CLI for browsing azure resources

This is a fantastic project created by [Lawrence Gripper](https://blog.gripdev.xyz) - see the [Getting Started](https://github.com/lawrencegripper/azbrowse/blob/master/docs/getting-started.md) docs for a taster of some of the functionality.

I've [contributed various PRs](https://github.com/lawrencegripper/azbrowse/pulls?q=is%3Apr+is%3Aclosed+author%3Astuartleeks), including:
 - Added Azure API spec parsing to allow digging deeper into Azure Resource Manager (ARM) endpoints
 - Enabling editing of JSON and submitting to ARM (where PUT/POST is supported) to make changes to Azure resources
 - Early work to export Azure resources as Terraform
 - Custom actions for nodes
 - Data-plane support for
   - Storage blobs
   - Container Registry
   - Kubernetes Service (allows drill-down into the Kubernetes API)
   - Cosmos DB (SQL Database endpoint)
   - Databricks (allows drill-down into the Databricks API) 

### VS Code Remote Containers (aka devcontainers)

Contributed the initial work to enable devcontainers to work with source code in WSL 2: https://github.com/microsoft/vscode-docs/blob/master/remote-release-notes/v1_44.md#progress-on-wsl-and-wsl-2-support

### Terraform `azurerm` provider

I've made a few contributions to the [`azurerm` provider for Terraform](https://github.com/terraform-providers/terraform-provider-azurerm/) improving support for Azure Batch, Azure Storage, Application Insights, and setting ACLs in Azure Data Lake.

### Azure Resource Explorer - a site to explore and manage your ARM resources in style

The code for <https://resources.azure.com> lives at <https://github.com/projectkudu/AzureResourceExplorer> and I've made a few contributions there to add and update API sets.

### Azure Databricks Operator

A fellow team started the [Azure Databricks Operator](https://github.com/microsoft/azure-databricks-operator/) project to create a Kubernetes operator for working with Azure Databricks and as part of a customer engagement I've made several contributions to the project.

### Terraform Databricks provider

After our team investigated and picked up the [Databrickslabs Terraform provider](https://github.com/databrickslabs/terraform-provider-databricks) for a project we were working on, [I contributed back a few fixes and enhancements](https://github.com/databrickslabs/terraform-provider-databricks/pulls?q=is%3Apr+is%3Aclosed+author%3Astuartleeks).

### BrowserPicker

When working with multiple browser profiles, it can become cumbersome to have to manually switch profiles when opening links. The [BrowserPicker](https://github.com/mortenn/BrowserPicker) project is an application that registers as your Windows Browser and then allows you to choose which browser/profile to open when clicking on a link. Rules can be configured to automate browser/profile selection base on the URL.

I [contributed a number of PRs](https://github.com/mortenn/BrowserPicker/pulls?q=is%3Apr+author%3Astuartleeks+is%3Aclosed) to add greater flexibility around URL matching in rules and to unwrap URLs in Outlook/Teams/Twitter links so that rules can work against the underlying URL rather than the wrapped URL. 

## My Projects

### wsl-clock - automatically correct clock drift

There has been a [long-running issue](https://github.com/microsoft/WSL/issues/4245) (now tracked [here](https://github.com/microsoft/WSL/issues/5324)) with WSL 2 where the clock in WSL 2 ends up behind the main system time. This causes a wide range of issues (for example, access tokens may be issued that the system doesn't think are valid).

After tracking this down to something that only seems to happen after sleep/hibernation, I created a PowerShell script that is triggered on system resume and automates applying the step to correct the clock. I later updated this to be a command line app written in Go - see [https://github.com/stuartleeks/wsl-clock](https://github.com/stuartleeks/wsl-clock).

### Dev container CLI

I'm [quite a big fan](https://stuartleeks.com/posts/vscode-devcontainers/) of the [dev containers feature of VS Code](https://code.visualstudio.com/docs/remote/containers) (especially [with WSL 2](#vs-code-remote-containers-aka-devcontainers)) and included a whole chapter on them in [my WSL 2 book](https://wsl.tips/book).

I also spend quite a bit of time working in the Terminal, so created a [`devcontainer` CLI](https://github.com/stuartleeks/devcontainer-cli). This CLI allows you to:

 - `devcontainer open-in-code` to open a folder in VS Code as a dev container (skipping the normal interim step where VS Code prompts you to reload as a dev container)
 - `devcontainer exec` to `exec` into a dev container (analagous to `docker exec`) - useful for dropping your terminal session into a dev container
 - `devcontainer template add` to copy a template dev container into your project to create a devcontainer - a handy way to get started
 - `devcontainer template add-link` to symlink a dev container template into your project with a `.gitignore` to exclude the folder - useful if you want to work with a dev container on a project that doesn't want the dev container contributed 

### az group deployment watch - Azure CLI extension

An extension for the Azure CLI to give a live progress view of an ARM deployment, complete with colour-coding to indicate status (running, completed, errored).

Code at: <https://github.com/stuartleeks/az-cli-extension-show-deployment>

### Posh-HumpCompletion - PowerShell tab completion for the Azure PowerShell cmdlets era

When working with some PowerShell modules, there can be a large number of cmdlets, and the cmdlet names can get quite long. posh-HumpCompletion adds support for "hump completion". This means that it will use the capitals in the cmdlet name as the identifiers, i.e. `Get-DC<tab>` would complete for `Get-DnsClient`, `Get-DnsClientCache`, `Get-DscConfiguration`, `Get-DomainController` etc.

Code at <https://github.com/stuartleeks/posh-humpcompletion>

### pi-bell - a Raspberry Pi powered networked doorbell

The [pi-bell](https://github.com/stuartleeks/pi-bell) is a networked doorbell project written in Go for the Raspberry Pi. It allows multiple chimes to be connected over the network to a bellpush.

### Kips-operator - an exploration of Kubernetes operators and Azure Relay Bridge

This project was an opportunity to explore building Kubernetes operators with Kubebuilder. It takes the [Azure Relay Bridge](https://github.com/clemensv/azure-relay-bridge) that [Clemens Vasters](https://twitter.com/clemensv) created and integrates it with an operator to provide a way to redirect services running in your Kubernetes cluster to applications running on your local machine.

Code at: <https://github.com/stuartleeks/kips-operator>

### DurableFunctionsTypedSafeActivities

An exploration of an idea for how to improve the developer experience of working with Azure Durable Functions to gain productivity and compiler checking by using code generation to avoid the need for magic strings.

Code at: <https://github.com/stuartleeks/DurableFunctionsTypedSafeActivities>

### Workshop material for "Building a provider for Virtual Kubelet"

[Building a provider for Virtual Kubelet](https://github.com/stuartleeks/virtual-kubelet-workshop-building-a-provider/) (with links to sample lab implementations in [Go](https://github.com/stuartleeks/virtual-kubelet-web-mock-go), [Node.js](https://github.com/stuartleeks/virtual-kubelet-web-mock-nodejs), [C#](https://github.com/stuartleeks/virtual-kubelet-web-mock-csharp/) and [Python](https://github.com/stuartleeks/virtual-kubelet-web-mock-python) as well as a [UI to help see the status of the provider](https://github.com/stuartleeks/virtual-kubelet-web-ui))

Delivered at [KubeCon Seattle 2018]({{< relref "writing-and-speaking.md#december-2018---kubecon-seattle---preconference-workshops-on-virtual-kubelet" >}}) and [Container Camp London 2018]({{< relref "writing-and-speaking.md#september-2018---container-camp-london---preconference-workshops-on-virtual-kubelet" >}})

