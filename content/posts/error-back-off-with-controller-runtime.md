---
type: post
title: "Error Back-off with Controller Runtime"
date: 2020-02-02T07:39:27Z
draft: false
categories:
 - technical
 - kubernetes
tags:
 - golang
 - kubernetes
 - kubebuilder
 - controller-runtime
---

[Kubebuilder](https://github.com/kubernetes-sigs/kubebuilder) provides tooling to help get you started quickly writing [operators](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/) for Kubernetes, and builds on top of [controller-runtime](https://github.com/kubernetes-sigs/controller-runtime). I've been looking at how errors are handled in a couple of Kubebuilder projects recently. I'd seen a couple of GitHub issues that mentioned that controller-runtime has back-off behaviour for errors so started looking through the docs to find out more, but didn't find anything. If I get chance, I'd like to find a suitable place to send a PR to add some details in the docs, but for now I'm collating my notes here as a reference for future me!

## Baseline

As a starting point, the code below is a simple `Reconcile` loop. Along with this code there is a [Custom Resource Definition](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) for a `Demo` object, and the `Reconcile` function is invoked by controller-runtime whenever a `Demo` object is created, updated or deleted.

```go {linenos=true}
func (r *DemoReconciler) Reconcile(req ctrl.Request) (ctrl.Result, error) {
	ctx := context.Background()
	log := r.Log.WithValues("demo", req.NamespacedName)

	log.Info("Starting")

	demo := &testv1alpha1.Demo{}
	if err := r.Get(ctx, req.NamespacedName, demo); err != nil {
		if apierrs.IsNotFound(err) {
			return ctrl.Result{}, nil
		}
		log.Error(err, "Error fetching Demo")
		return ctrl.Result{}, err
    }
    
    // Typically there would be some reconciliation logic here!

	return ctrl.Result{}, nil
}
```

As you can see in the definition of the `Reconcile` method above, it takes in a `Request` instance (defined in controller-runtime) and returns a `Result` (again defined in controller-runtime) and an `error`.

The first few lines of the `Reconcile` method are setting up some variables, and then the main block in the middle is looking up the `Demo` instead based on the metadata in the `req` parameter, and handling errors. Finally, after not really doing anything, the method returns an empty `Result` and `nil` error.

If we run this and create a `Demo` object we would see log output similar to the output below showing the reconciler starting and successfully completing.

```log
2020-02-02T07:06:42.513Z	INFO	controllers.Demo	Starting	{"demo": "default/demo-sample"}
2020-02-02T07:06:42.514Z	DEBUG	controller-runtime.controller	Successfully Reconciled	{"controller": "demo", "request": "default/demo-sample"}
```

## Adding in Errors

Now let's change the last line of the reconciler to return an error:

```go
	return ctrl.Result{}, fmt.Errorf("dummy error")
```

If we run the same test as before we now start to see error messages in the logs as shown in the output below. Note that the full error details have been stripped out as it is quite noisy. It is clear that the reconciler was invoked more than once for the same object. This standard behaviour with controller-runtime; if you return an error it will retry the execution of the `Reconcile` function.

Looking at the timestamps we can see that the first few retries happen very quickly, but the gap between retries starts to increase. controller-runtime is automatically implementing a retry back-off for us!

```log
2020-02-02T06:51:18.288Z	INFO	controllers.Demo	Starting	{"demo": "default/demo-sample"}
2020-02-02T06:51:18.288Z	ERROR	controller-runtime.controller	Reconciler error	{"controller": "demo", "request": "default/demo-sample", "error": "dummy error"}
2020-02-02T06:51:19.289Z	INFO	controllers.Demo	Starting	{"demo": "default/demo-sample"}
2020-02-02T06:51:19.289Z	ERROR	controller-runtime.controller	Reconciler error	{"controller": "demo", "request": "default/demo-sample", "error": "dummy error"}
2020-02-02T06:51:20.289Z	INFO	controllers.Demo	Starting	{"demo": "default/demo-sample"}
2020-02-02T06:51:20.289Z	ERROR	controller-runtime.controller	Reconciler error	{"controller": "demo", "request": "default/demo-sample", "error": "dummy error"}
2020-02-02T06:51:21.290Z	INFO	controllers.Demo	Starting	{"demo": "default/demo-sample"}
2020-02-02T06:51:21.290Z	ERROR	controller-runtime.controller	Reconciler error	{"controller": "demo", "request": "default/demo-sample", "error": "dummy error"}
2020-02-02T06:51:22.290Z	INFO	controllers.Demo	Starting	{"demo": "default/demo-sample"}
2020-02-02T06:51:22.291Z	ERROR	controller-runtime.controller	Reconciler error	{"controller": "demo", "request": "default/demo-sample", "error": "dummy error"}
2020-02-02T06:51:23.291Z	INFO	controllers.Demo	Starting	{"demo": "default/demo-sample"}
2020-02-02T06:51:23.291Z	ERROR	controller-runtime.controller	Reconciler error	{"controller": "demo", "request": "default/demo-sample", "error": "dummy error"}
2020-02-02T06:51:24.315Z	INFO	controllers.Demo	Starting	{"demo": "default/demo-sample"}
2020-02-02T06:51:24.316Z	ERROR	controller-runtime.controller	Reconciler error	{"controller": "demo", "request": "default/demo-sample", "error": "dummy error"}
2020-02-02T06:51:25.316Z	INFO	controllers.Demo	Starting	{"demo": "default/demo-sample"}
2020-02-02T06:51:25.317Z	ERROR	controller-runtime.controller	Reconciler error	{"controller": "demo", "request": "default/demo-sample", "error": "dummy error"}
2020-02-02T06:51:26.317Z	INFO	controllers.Demo	Starting	{"demo": "default/demo-sample"}
2020-02-02T06:51:26.318Z	ERROR	controller-runtime.controller	Reconciler error	{"controller": "demo", "request": "default/demo-sample", "error": "dummy error"}
2020-02-02T06:51:27.598Z	INFO	controllers.Demo	Starting	{"demo": "default/demo-sample"}
2020-02-02T06:51:27.598Z	ERROR	controller-runtime.controller	Reconciler error	{"controller": "demo", "request": "default/demo-sample", "error": "dummy error"}
2020-02-02T06:51:30.158Z	INFO	controllers.Demo	Starting	{"demo": "default/demo-sample"}
2020-02-02T06:51:30.158Z	ERROR	controller-runtime.controller	Reconciler error	{"controller": "demo", "request": "default/demo-sample", "error": "dummy error"}
2020-02-02T06:51:35.279Z	INFO	controllers.Demo	Starting	{"demo": "default/demo-sample"}
2020-02-02T06:51:35.280Z	ERROR	controller-runtime.controller	Reconciler error	{"controller": "demo", "request": "default/demo-sample", "error": "dummy error"}
2020-02-02T06:51:45.520Z	INFO	controllers.Demo	Starting	{"demo": "default/demo-sample"}
2020-02-02T06:51:45.520Z	ERROR	controller-runtime.controller	Reconciler error	{"controller": "demo", "request": "default/demo-sample", "error": "dummy error"}
2020-02-02T06:52:06.001Z	INFO	controllers.Demo	Starting	{"demo": "default/demo-sample"}
2020-02-02T06:52:06.001Z	DEBUG	controller-runtime.controller	Successfully Reconciled	{"controller": "demo", "request": "default/demo-sample"}
```

## Digging into the Code

In this section we'll explore the back-off behaviour seen above by digging into the libraries that our controller is built on, following the trail of the implementation to find where (and how) it is implemented. If you just want the end results of this then skip to the [Summary](#summary) section.

Starting in the Kubebuilder-generated project, the `Reconcile` method on our controller is wired up in the `SetupWithManager` function shown below.

```go {linenos=true}
func (r *FooReconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&testv1alpha1.Foo{}).
		Complete(r)
}
```

This provides a starting point for digging into the controller-runtime code and as we do we reach [this code which creates a `Controller`](https://github.com/kubernetes-sigs/controller-runtime/blob/8c39906c77cdb574482c01fcd74a76b105b06522/pkg/controller/controller.go#L90). Lines 8-12 below show where the rate-limiting queue is created.

```go {linenos=true, hl_lines=["8-12"]}
	c := &controller.Controller{
		Do:       options.Reconciler,
		Cache:    mgr.GetCache(),
		Config:   mgr.GetConfig(),
		Scheme:   mgr.GetScheme(),
		Client:   mgr.GetClient(),
		Recorder: mgr.GetEventRecorderFor(name),
		MakeQueue: func() workqueue.RateLimitingInterface {
			return workqueue.NewNamedRateLimitingQueue(
				workqueue.DefaultControllerRateLimiter(), 
				name)
		},
		MaxConcurrentReconciles: options.MaxConcurrentReconciles,
		Name:                    name,
	}
```

Note that the `NewNamedRateLimitingQueue` takes a `workqueue.DefaultControllerRateLimiter` as a parameter. We'll come back to explore that in a moment, but for now we'll look at the  [NewNamedRateLimitingQueue](https://github.com/kubernetes/client-go/blob/a432bd9ba7da427ae0a38a6889d72136bce4c4ea/util/workqueue/rate_limiting_queue.go#L44-L49) (from the `client-go` package) which is shown below.

```go {linenos=true}
func NewNamedRateLimitingQueue(rateLimiter RateLimiter, name string) RateLimitingInterface {
	return &rateLimitingType{
		DelayingInterface: NewNamedDelayingQueue(name),
		rateLimiter:       rateLimiter,
	}
}
```

As you can see from the implementation this uses an internal `rateLimitingType`, which has a few functions defined:

```go {linenos=true,hl_lines=["2-4"]}
// AddRateLimited AddAfter's the item based on the time when the rate limiter says it's ok
func (q *rateLimitingType) AddRateLimited(item interface{}) {
	q.DelayingInterface.AddAfter(item, q.rateLimiter.When(item))
}

func (q *rateLimitingType) NumRequeues(item interface{}) int {
	return q.rateLimiter.NumRequeues(item)
}

func (q *rateLimitingType) Forget(item interface{}) {
	q.rateLimiter.Forget(item)
}
```

The `AddRateLimited` function is interesting as it uses the `rateLimiter` to determine where the specified item should be added in the queue (i.e. what time it should be available for de-queueing). As we saw in the call to `NewNamedRateLimitingQueue`, the rate limiter is returned from `workqueue.DefaultControllerRateLimiter` (also in [client-go](https://github.com/kubernetes/client-go/blob/a432bd9ba7da427ae0a38a6889d72136bce4c4ea/util/workqueue/default_rate_limiters.go#L39-L45)) shown below:

```go {linenos=true}
// DefaultControllerRateLimiter is a no-arg constructor for a default rate limiter for a workqueue.  It has
// both overall and per-item rate limiting.  The overall is a token bucket and the per-item is exponential
func DefaultControllerRateLimiter() RateLimiter {
	return NewMaxOfRateLimiter(
		NewItemExponentialFailureRateLimiter(5*time.Millisecond, 1000*time.Second),
		// 10 qps, 100 bucket size.  This is only for retry speed and its only the overall factor (not per item)
		&BucketRateLimiter{Limiter: rate.NewLimiter(rate.Limit(10), 100)},
	)
}
```

This is the rate-limiter that `AddRateLimited` uses to determine when items should be enqueued for. [`MaxOfRateLimiter.When`](https://github.com/kubernetes/client-go/blob/a432bd9ba7da427ae0a38a6889d72136bce4c4ea/util/workqueue/default_rate_limiters.go#L179-L189) takes the longest duration of the encapsulated rate-limiters, as shown below. 

```go {linenos=true}
func (r *MaxOfRateLimiter) When(item interface{}) time.Duration {
	ret := time.Duration(0)
	for _, limiter := range r.limiters {
		curr := limiter.When(item)
		if curr > ret {
			ret = curr
		}
	}

	return ret
}
```

So now we know that items added to the work queue using `AddRateLimited` will get a per-item exponential back-off *and* 10 items per second limit (with a burst allowance of 100). The next step is to determine when items are added to the queue using `AddRateLimited`.

The code we saw earlier that creates the work queue assigned that as part of initialising a `controller.Controller` instance. The `Controller` type in this context is in the [internal/controller/controller.go](https://github.com/kubernetes-sigs/controller-runtime/blob/8c39906c77cdb574482c01fcd74a76b105b06522/pkg/internal/controller/controller.go#L256-L275) in controller-runtime which has the following logic in it's `reconcileHandler` method:


```go {linenos=true}
	if result, err := c.Do.Reconcile(req); err != nil {
		c.Queue.AddRateLimited(req)
		log.Error(err, "Reconciler error", "controller", c.Name, "request", req)
		ctrlmetrics.ReconcileErrors.WithLabelValues(c.Name).Inc()
		ctrlmetrics.ReconcileTotal.WithLabelValues(c.Name, "error").Inc()
		return false
	} else if result.RequeueAfter > 0 {
		// The result.RequeueAfter request will be lost, if it is returned
		// along with a non-nil error. But this is intended as
		// We need to drive to stable reconcile loops before queuing due
		// to result.RequestAfter
		c.Queue.Forget(obj)
		c.Queue.AddAfter(req, result.RequeueAfter)
		ctrlmetrics.ReconcileTotal.WithLabelValues(c.Name, "requeue_after").Inc()
		return true
	} else if result.Requeue {
		c.Queue.AddRateLimited(req)
		ctrlmetrics.ReconcileTotal.WithLabelValues(c.Name, "requeue").Inc()
		return true
	}
```

In this code, the `c.Do.Reconcile` is the `Reconcile` method from our operator, so we can see that `Reconcile` calls that return an error or set `Requeue: true` on the `Result` will result in calls to `AddAfter` and will have the exponential back-off and 10 events per second rate limiting applied. We can also see that setting `RequeueAfter: someDuration` does *not* result in rate-limiting being applied.

## New items

The previous section gives us a clear picture of when rate-limiting is applied, but what about new instances of our CRD? Are we rate-limited on those?

To answer that we can go back to the `SetupWithManager` code that we saw earlier. Repeating the process of the following the thread of the code, we can see that the `Complete` method calls `Build`, which then calls [the `doWatch` method](https://github.com/kubernetes-sigs/controller-runtime/blob/8c39906c77cdb574482c01fcd74a76b105b06522/pkg/builder/controller.go#L158-L187):

```go {linenos=true}
func (blder *Builder) doWatch() error {
	// Reconcile type
	src := &source.Kind{Type: blder.apiType}
	hdler := &handler.EnqueueRequestForObject{}
	err := blder.ctrl.Watch(src, hdler, blder.predicates...)
	if err != nil {
		return err
	}

	// code ommitted for brevity

	return nil
}
```

Here we can see `bldr.ctrl.Watch` being invoked for a `handler.EnqueueRequestForObject` on a `source.Kind`. Tracking through the `Watch` method we find that this is implemented in the [`Controller.Watch` method](https://github.com/kubernetes-sigs/controller-runtime/blob/8c39906c77cdb574482c01fcd74a76b105b06522/pkg/internal/controller/controller.go#L119-L144) which calls into the [`Controller.Start` method](https://github.com/kubernetes-sigs/controller-runtime/blob/8c39906c77cdb574482c01fcd74a76b105b06522/pkg/internal/controller/controller.go#L146-L207). This in turn calls the [`Start` method](https://github.com/kubernetes-sigs/controller-runtime/blob/8c39906c77cdb574482c01fcd74a76b105b06522/pkg/source/source.go#L71-L96) on `Source.Kind`. This method uses an `EventHandler` to wrap the event handler that was passed in. [This code](https://github.com/kubernetes-sigs/controller-runtime/blob/8c39906c77cdb574482c01fcd74a76b105b06522/pkg/source/internal/eventsource.go#L46-L76) has `OnAdd` (shown below), `OnUpdate` and `OnDelete` methods.

```go {linenos=true}
func (e EventHandler) OnAdd(obj interface{}) {
	c := event.CreateEvent{}

	// code omitted for brevity

	for _, p := range e.Predicates {
		if !p.Create(c) {
			return
		}
	}

	// Invoke create handler
	e.EventHandler.Create(c, e.Queue)
}
```

The snippet above omits the code to load the metadata, but once loaded it calls any predicates that were specified when setting up the controller. This is where the predicates from the previous posts on filtering [deletes]({{< relref kubebuilder-event-filters-part-1-delete.md >}}) and [updates]({{< relref kubebuilder-event-filters-part-2-update.md >}}) are executed.

The code for `OnUpdate` and `OnDelete` is similar - if no predicate returns false the code goes on to call the `Update` or `Delete` method on the event handler. This event handler is the one that was passed down from the `doWatch` method which was a `handler.EnqueueRequestForObject`. Looking at the code for the [`EnqueueRequestForObject.Create` method](https://github.com/kubernetes-sigs/controller-runtime/blob/8c39906c77cdb574482c01fcd74a76b105b06522/pkg/handler/enqueue.go#L37-L47):

```go {linenos=true}
func (e *EnqueueRequestForObject) Create(evt event.CreateEvent, q workqueue.RateLimitingInterface) {
	if evt.Meta == nil {
		enqueueLog.Error(nil, "CreateEvent received with no metadata", "event", evt)
		return
	}
	q.Add(reconcile.Request{NamespacedName: types.NamespacedName{
		Name:      evt.Meta.GetName(),
		Namespace: evt.Meta.GetNamespace(),
	}})
}
```

In this code we can see that the event is being added to the queue using `Add` rather than `AddAfter`, so no rate-limiting is applied to the incoming events.

## Summary

This post ended up being a bit of a journey through the [controller-runtime](https://github.com/kubernetes-sigs/controller-runtime) and [client-go](https://github.com/kubernetes/client-go) codebases, but coming out the other side we now know that

* rate-limiting *is not* applied to incoming events (e.g. new watched items)
* rate-limiting *is* applied to reconcile responses with an error or that set `Requeue: true`
* rate-limiting *is not* applied to reconcile responses that set `RequeueAfter: someDuration`

When rate-limiting is applied it is the combination of:

* a per-item exponential back-off
* and `rate.NewLimiter(10, 100)` (i.e. rate limit of 10 per second and burst amount of 100) 

At the time of writing, this rate-limiting cannot be configured but there is a [pull request open](https://github.com/kubernetes-sigs/controller-runtime/pull/731) to allow the rate-limiter to be specified in the options in `SetupWithManager`.
