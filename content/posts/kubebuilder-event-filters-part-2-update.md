---
type: post
title: "Using Event Filters with Kubebuilder"
date: 2020-01-17T08:34:41Z
draft: false
subtitle: "Part 2: Filtering Updates"
categories:
 - technical
 - kubernetes
tags:
 - kubernetes
 - kubebuilder
 - operators
 - controller-runtime
---


## Background

As I [recently posted]({{< relref kubebuilder-event-filters-part-1-delete.md >}}), I've worked on a couple of projects that have involved using [Kubebuilder](https://github.com/kubernetes-sigs/kubebuilder) to create [Kubernetes operators](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/).

In [last post]({{< relref kubebuilder-event-filters-part-1-delete.md >}}) we looked at using event filters to prevent delete notifications being processed by the reconciliation loop. Another thing I've noticed as I've been developing operators is that the flow when an object is created is typically: receive create notification, take some action, update the object `Status` property. It turns out that updating the `Status` triggers the reconciliation loop again (this also happens when you add a finalizer)! In this post we'll look at filtering out these updates that occur due to the `Status` object changing.

## Implementing the filter


Here's the code we had last time with an `UpdateFunc` added:

```go {hl_lines=["5-8"]}
func (r *CronJobReconciler) SetupWithManager(mgr ctrl.Manager) error {
    return ctrl.NewControllerManagedBy(mgr).
        For(&batch.CronJob{}).
        WithEventFilter(predicate.Funcs{
            UpdateFunc: func(e event.UpdateEvent) bool {
                // TODO - add filter logic here!
                return true
            },
            DeleteFunc: func(e event.DeleteEvent) bool {
                // The reconciler adds a finalizer so we perform clean-up
                // when the delete timestamp is added
                // Suppress Delete events to avoid filtering them out in the Reconcile function
                return false
            },
        }).
        Complete(r)
}
```

In the delete case, we simply returned `false` to suppress all delete notifications. For the update case, we want to process any changes to the `Spec`, but ignore `Status` changes.

Fortunately, there is a metadata field that we can make use of. From the [Custom Resource Definition docs](https://kubernetes.io/docs/tasks/access-kubernetes-api/custom-resources/custom-resource-definitions/#status-subresource):

> The .metadata.generation value is incremented for all changes, except for changes to .metadata or .status

The `Generation` metadata property is perfect: it will be updated when the `Spec` changes and we have access to the metadata for both old and new objects in the `UpdateFunc`:

```go
func (r *CronJobReconciler) SetupWithManager(mgr ctrl.Manager) error {
    return ctrl.NewControllerManagedBy(mgr).
        For(&batch.CronJob{}).
        WithEventFilter(predicate.Funcs{
            UpdateFunc: func(e event.UpdateEvent) bool {
                oldGeneration := e.MetaOld.GetGeneration()
                newGeneration := e.MetaNew.GetGeneration()
                // Generation is only updated on spec changes (also on deletion),
                // not metadata or status
                // Filter out events where the generation hasn't changed to
                // avoid being triggered by status updates
                return oldGeneration != newGeneration
            },
            DeleteFunc: func(e event.DeleteEvent) bool {
                // The reconciler adds a finalizer so we perform clean-up
                // when the delete timestamp is added
                // Suppress Delete events to avoid filtering them out in the Reconcile function
                return false
            },
        }).
        Complete(r)
}
```

## Conclusion

With this extra event filter, we now have better control over when the reconciliation loop is triggered. It will no longer be triggered by adding a finalizer or updating the `Status`, but will still be triggereed by external changes to the `Spec` or by our code scheduling a Requeue.
