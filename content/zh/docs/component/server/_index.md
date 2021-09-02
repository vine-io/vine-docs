---
title: "内部服务"
date: 2020-12-29T15:00:10+08:00
draft: false
weight: 30
description: >
---

```go
// Server is a simple vine server abstraction
type Server interface {
	// Init initialise options
	Init(...Option) error
	// Options retrieve the options
	Options() Options
	// Handle register a handler
	Handle(Handler) error
	// NewHandler create a new handler
	NewHandler(interface{}, ...HandlerOption) Handler
	// NewSubscriber create a new subscriber
	NewSubscriber(string, interface{}, ...SubscriberOption) Subscriber
	// Subscribe register a subscriber
	Subscribe(Subscriber) error
	// Start the server
	Start() error
	// Stop the server
	Stop() error
	// String implementation
	String() string
}
```