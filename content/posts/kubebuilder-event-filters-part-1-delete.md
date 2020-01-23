---
type: post
title: "Using Event Filters with Kubebuilder"
date: 2020-01-06T07:34:41Z
draft: false
subtitle: "Part 1: Filtering Deletes"
categories:
 - technical
 - kubernetes
tags:
 - kubernetes
 - kubebuilder
 - operators
aliases:
 - /post/kubebuilder-event-filters-part-1-delete/
---

**UPDATE (2020/01/08 ):** After testing this in another project I discovered that the `NotFound` checking is still required in the case where the reconciliation has been requeued and the object is deleted in the interim period. Even with this code, I still prefer not having the `NotFound` output in my logs for the default case.

## Background

A couple of projects recently have involved using [Kubebuilder](https://github.com/kubernetes-sigs/kubebuilder) to create [Kubernetes operators](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/).

Kubebuilder scaffolds out a go application and then lets you focus on writing the logic of the reconciliation loop which is the core part of the operator. For getting started with Kubebuilder there is [Kubebuilder book](https://book.kubebuilder.io) which is a great walkthrough of creating a controller.

The reconciliation loop is invoked whenever one of the watched objects is created, modified or deleted. The first step in the reconciliation loop is typically to retrieve the object that triggered the invocation. Deletion is an interesting case as by the time the reconciliation loop is invoked the object no longer exists. Fortunately, Kubernetes has a concept called finalizers. If you add a finalizer to an object then when someone requests its deletion Kubernetes only marks is a being deleted (and then waits for the finalizers to be removed). In terms of the reconciliation loop, this means that it is invoked upon deletion but before the object is actually deleted allowing the object's details to be retrieved to be used in any clean-up steps.

So far, so good. Unfortunately, the reconcilation loop is still invoked when the object is deleted which means that you end up with code such as the following (taken from the Kubebuilder book):

```go {hl_lines=[7]}
var cronJob batch.CronJob
if err := r.Get(ctx, req.NamespacedName, &cronJob); err != nil {
    log.Error(err, "unable to fetch CronJob")
    // we'll ignore not-found errors, since they can't be fixed by an immediate
    // requeue (we'll need to wait for a new notification), and we can get them
    // on deleted requests.
    return ctrl.Result{}, ignoreNotFound(err)
}
```

The subtlety of this code snippet was lost on me the first time I encountered it: the return statement calls `ignoreNotFound(err)` which returns `nil` if `err` is a `NotFound` error and returns the original error otherwise. The above snippet always calls `log.Error` which is quite verbose in the log output, so I prefer to write the code as something similar to this:

```go {hl_lines=[7]}
var cronJob batch.CronJob
if err := r.Get(ctx, req.NamespacedName, &cronJob); err != nil {
    if apierrs.IsNotFound(err) {
        log.Info("Unable to fetch CronJob - skipping")
        return ctrl.Result{}, nil
    }
    log.Error(err, "unable to fetch CronJob")
    return ctrl.Result{}, err
}
```

Even this still didn't sit quite right with me. I just didn't want to get a notification for a deleted object! Fortunately there is a way to achieve that...

## Enter Event Filters

The code that Kubebuilder scaffolds includes some code to wire up your operator to handle events:

```go
func (r *CronJobReconciler) SetupWithManager(mgr ctrl.Manager) error {
    return ctrl.NewControllerManagedBy(mgr).
        For(&batch.CronJob{}).
        Complete(r)
}
```

It turns out that there is a [`WithEventFilter`](https://godoc.org/github.com/kubernetes-sigs/controller-runtime/pkg/builder#Builder.WithEventFilter) function that can be chained into this setup which lets you specify predicate functions to filter out specific events/invocations. `WithEventFilter` takes a [`Predicate`](https://godoc.org/sigs.k8s.io/controller-runtime/pkg/predicate#Predicate) interface which has different predicate functions based on the type of the event:

```go
type Predicate interface {
    // Create returns true if the Create event should be processed
    Create(event.CreateEvent) bool

    // Delete returns true if the Delete event should be processed
    Delete(event.DeleteEvent) bool

    // Update returns true if the Update event should be processed
    Update(event.UpdateEvent) bool

    // Generic returns true if the Generic event should be processed
    Generic(event.GenericEvent) bool
}
```

Since the reconiliation loop wasn't taking any action when invoked after the item is actually deleted the predicate for delete events can simply return `false`! There is also a handy [`Funcs`](https://godoc.org/sigs.k8s.io/controller-runtime/pkg/predicate#Funcs) type that implements the `Predicate` interface and allows you to pass in functions you want to use as predicates. Putting it all together to filter out the delete events, we have:

```go
func (r *CronJobReconciler) SetupWithManager(mgr ctrl.Manager) error {
    return ctrl.NewControllerManagedBy(mgr).
        For(&batch.CronJob{}).
        WithEventFilter(predicate.Funcs{
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

Kubebuilder scaffolds a project for us and allows us to mostly focus on the reconciliation logic that is the core of the operator code. I initially overlooked a lot of the rest of the code but it gives some interesting opportunities such as those shown here. In a future post I'll look at an example for the `UpdateFunc` predicate - stay tuned...
