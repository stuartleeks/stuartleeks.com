---
title: "Connection re-use in Golang with http.Client"
date: 2020-01-08T20:45:55Z
draft: false
---

Just before Christmas I was working with [Eliise](https://dev.to/eliises/) and [Lawrence](https://blog.gripdev.xyz/) and we observed socket exhaustion during load testing of a Golang application that makes HTTP requests against an API. I hoped for a quick win and had a quick scan of the code but that confirmed that the was correctly reading the `Body` and calling `Close` - time to dig a bit deeper.

After some head-scratching we noticed that the code creates a new `http.Client` for each request. Not only that, when it creates the `http.Client` it also assigns a [`Transport`](https://godoc.org/net/http#Transport) instance. This last piece is very important - the docs for `Transport` state:

> By default, Transport caches connections for future re-use. This may leave many open connections when accessing many hosts. This behavior can be managed using Transport's CloseIdleConnections method and the MaxIdleConnsPerHost and DisableKeepAlives fields.

and then goes on to say

> Transports should be reused instead of created as needed. Transports are safe for concurrent use by multiple goroutines.

That means that any of the examples below will re-use connections (assuming that the Body is fully read and closed.)

Using `DefaultClient`:

```go
    // Uses http.DefaultClient which in turn uses the same http.DefaultTransport instance
    http.Get("http://example.com")
```

Not specifying the `Transport` so using `DefaultTransport`:

```go
    // Transport not set, so http.DefaultTransport instance is used
    client := &http.Client{}
    client.Get("http://example.com")
```

Using a shared `Transport` value:

```go
    // Transport set to a cached value
    client := &http.Client{
        Transport: transport, // assuming that transport is a fixed value for this example!
    }
    client.Get("http://example.com")
```

However, what will ***not*** work (from the perspective of re-using connections) is to create a new `Transport` instance for each `http.Client`:

```go
    // New Transport for each client/call means that connections cannot be re-used
    // This leads to port exhaustion under load :-(
    client := &http.Client{
        Transport: &http.Transport{
            // insert config here
        },
    }
    client.Get("http://example.com")
```

Since we were in the category of the last example, the code we were testing wasn't re-using connection across requests which triggered the port-exhaustion under load. A tweak to cache the `http.Client` across requests (as per the go docs) and we were back off and testing again!
