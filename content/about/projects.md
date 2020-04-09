---
title: "Projects and contributions"
date: 2020-01-08T16:34:05Z
draft: false
type: page
---

## Projects

### az group deployment watch - Azure CLI extension

An extension for the Azure CLI to give a live progress view of an ARM deployment, complete with colour-coding to indicate status (running, completed, errored).

Code at: <https://github.com/stuartleeks/az-cli-extension-show-deployment>

### Posh-HumpCompletion - PowerShell tab completion for the Azure PowerShell cmdlets era

When working with some PowerShell modules, there can be a large number of cmdlets, and the cmdlet names can get quite long. posh-HumpCompletion adds support for "hump completion". This means that it will use the capitals in the cmdlet name as the identifiers, i.e. `Get-DC<tab>` would complete for `Get-DnsClient`, `Get-DnsClientCache`, `Get-DscConfiguration`, `Get-DomainController` etc.

Code at <https://github.com/stuartleeks/posh-humpcompletion>

### Kips-operator - an exploration of Kubernetes operators and Azure Relay Bridge

This project was an opportunity to explore building Kubernetes operators with Kubebuilder. It takes the [Azure Relay Bridge](https://github.com/clemensv/azure-relay-bridge) that [Clemens Vasters](https://twitter.com/clemensv) created and integrates it with an operator to provide a way to redirect services running in your Kubernetes cluster to applications running on your local machine.

Code at: <https://github.com/stuartleeks/kips-operator>

### DurableFunctionsTypedSafeActivities

An exploration of an idea for how to improve the developer experience of working with Azure Durable Functions to gain productivity and compiler checking by using code generation to avoid the need for magic strings.

Code at: <https://github.com/stuartleeks/DurableFunctionsTypedSafeActivities>

### Workshop material for "Building a provider for Virtual Kubelet"

[Building a provider for Virtual Kubelet](https://github.com/stuartleeks/virtual-kubelet-workshop-building-a-provider/) (with links to sample lab implementations in [Go](https://github.com/stuartleeks/virtual-kubelet-web-mock-go), [Node.js](https://github.com/stuartleeks/virtual-kubelet-web-mock-nodejs), [C#](https://github.com/stuartleeks/virtual-kubelet-web-mock-csharp/) and [Python](https://github.com/stuartleeks/virtual-kubelet-web-mock-python) as well as a [UI to help see the status of the provider](https://github.com/stuartleeks/virtual-kubelet-web-ui))

Delivered at [KubeCon Seattle 2018]({{< relref "writing-and-speaking.md#december-2018---kubecon-seattle---preconference-workshops-on-virtual-kubelet" >}}) and [Container Camp London 2018]({{< relref "writing-and-speaking.md#september-2018---container-camp-london---preconference-workshops-on-virtual-kubelet" >}})

## Contributions

In addition to the projects above, I also enjoy contributing to other projects. To mention a few...

### azbrowse - an interactive CLI for browsing azure resources

This is a fantastic project created by [Lawrence Gripper](https://blog.gripdev.xyz) - see the [Getting Started](https://github.com/lawrencegripper/azbrowse/blob/master/docs/getting-started.md) docs for a taster of some of the functionality.

Project home: <https://github.com/lawrencegripper/azbrowse>

### Azure Resource Explorer - a site to explore and manage your ARM resources in style

The code for <https://resources.azure.com> lives at <https://github.com/projectkudu/AzureResourceExplorer> and I've made a few contributions there.

### Terraform Azure Rm provider

I've made a few contributions to the [AzureRm provider for Terraform](https://github.com/terraform-providers/terraform-provider-azurerm/) improving support for Azure Batch, Azure Storage and Application Insights.

### Azure Databricks Operator

A fellow team started the [Azure Databricks Operator](https://github.com/microsoft/azure-databricks-operator/) project to create a Kubernetes operator for working with Azure Databricks and as part of a customer engagement I've made several contributions to the project.

### VS Code Remote Containers (aka devcontainers)

Contributed the initial work to enable devcontainers to work with source code in WSL 2: https://github.com/microsoft/vscode-docs/blob/master/remote-release-notes/v1_44.md#progress-on-wsl-and-wsl-2-support