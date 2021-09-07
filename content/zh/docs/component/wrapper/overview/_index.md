---
title: "概述"
date: 2021-08-27T09:29:03+08:00
draft: false
weight: 1
description: >
---

## 简介
**Vine** 装载器等同于"中间件"。

> 中间件（英语：Middleware），又译中间件、中介层，是一类提供系统软件和应用软件之间连接、便于软件各部件之间的沟通的软件，应用软件可以借助中间件在不同的技术架构之间共享信息与资源。中间件位于客户机服务器的操作系统之上，管理着计算资源和网络通信。 -- 维基百科

## wrapper
**Vine** 中包含输入输出的 wrappr 分别在 `Client` 和 `Server` 中使用，定义如下:
```go
// client
type CallFunc func(ctx context.Context, node *registry.Node, req Request, rsp interface{}, opts CallOptions) error
// CallWrapper is a low level wrapper for the CallFunc
type CallWrapper func(CallFunc) CallFunc
// Wrapper wraps a client and returns a client
type Wrapper func(Client) Client
// StreamWrapper wraps a Stream and returns the equivalent
type StreamWrapper func(Stream) Stream

// server
// HandlerFunc represents a single method of a handler. It's used primarily
// for the wrappers. What's handed to the actual method is the concrete
// request and response types.
type HandlerFunc func(ctx context.Context, req Request, rsp interface{}) error
// SubscriberFunc represents a single method of a subscriber. It's used primarily
// for the wrappers. What's handed to the actual method is the concrete
// publication message.
type SubscriberFunc func(ctx context.Context, msg Message) error
// HandlerWrapper wraps the HandlerFunc and returns the equivalent
type HandlerWrapper func(HandlerFunc) HandlerFunc
// SubscriberWrapper wraps the SubscriberFunc and returns the equivalent
type SubscriberWrapper func(SubscriberFunc) SubscriberFunc
// StreamWrapper wraps a Stream interface and returns the equivalent.
// Because streams exist for the lifetime of a method invocation this
// is a convenient way to wrap a Stream as its in use for trace, monitoring.
// metrics, etc.
type StreamWrapper func(Stream) Stream
```
**Vine** 内部集成五中类型的 wrapper:
client wrapper:
- CallWrapper: 拦截 client Call 请求
- StreamWrapper: 拦截 client Stream 请求

server wrapper:
- HandlerWrapper: 拦截 grpc simple 请求
- SubscriberWrapper: 连接 broker 订阅
- StreamWrapper:  连接 grpc stream 请求
## 自定义 wrapper 
我们通过实例代码来说明 wrapper 的内部工作原理：
```go
package main

import (
	"context"
	"time"

	"github.com/vine-io/vine"
	"github.com/vine-io/vine/core/client"
	"github.com/vine-io/vine/core/registry"
	log "github.com/vine-io/vine/lib/logger"
)

func main() {
	vine.NewService(
        // 加载自定义的 wrapper
		vine.WrapCall(LoggerWrapper(), SubWrapper()),
	)
}

// 定义一个 CallWrapper, 拦截 client Call 请求
func LoggerWrapper() client.CallWrapper {
	return func(fn client.CallFunc) client.CallFunc {
		return func(ctx context.Context, node *registry.Node, req client.Request, rsp interface{}, opts client.CallOptions) error {

			log.Info("logger wrapper: before call")
			err := fn(ctx, node, req, rsp, opts)
			log.Info("logger wrapper: after call")

			return err
		}
	}
}

func SubWrapper() client.CallWrapper {
	return func(fn client.CallFunc) client.CallFunc {
		return func(ctx context.Context, node *registry.Node, req client.Request, rsp interface{}, opts client.CallOptions) error {

			log.Info("sub wrapper: before call")
			err := fn(ctx, node, req, rsp, opts)
			log.Info("sub wrapper: after call")

			return err
		}
	}
}
```
请求输出:
```bash
logger wrapper: before call
sub wrapper: before call
sub wrapper: after call
logger wrapper: after call
```
由此可见 wrapper 链路是一个 `"洋葱模型"`:

![](vinewrapper.png)