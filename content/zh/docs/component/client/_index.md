---
title: "内部请求"
date: 2020-12-29T14:59:49+08:00
draft: false
weight: 40
description: >
---

## 概述

`Client` 是微服务的核心模块，提供一个请求其他服务的工具，根据不同的实现，提供相应类型的接口。目前内部支持:

- grpc
- http

```go
type Client interface {
	Init(...Option) error
	Options() Options
	NewMessage(topic string, msg interface{}, opts ...MessageOption) Message
	NewRequest(service, endpoint string, req interface{}, reqOpts ...RequestOption) Request
	Call(ctx context.Context, req Request, rsp interface{}, opts ...CallOption) error
	Stream(ctx context.Context, req Request, opts ...CallOption) (Stream, error)
	Publish(ctx context.Context, msg Message, opts ...PublishOption) error
	String() string
}
```

## 使用方法

### 启动请求

```go
package main

import (
	"context"
	"fmt"
	"log"

	"github.com/vine-io/vine/core/broker/memory"
	"github.com/vine-io/vine/core/client"
	"github.com/vine-io/vine/core/client/grpc"
	"github.com/vine-io/vine/core/registry/mdns"
	pb "github.com/vine-io/vine/testdata/proto"
)

func main() {
    // 新建一个新的 gRPC Client
	cc := grpc.NewClient(
		client.Registry(mdns.NewRegistry()),
		client.Broker(memory.NewBroker()),
	)
    // 初始化
	if err := cc.Init(); err != nil {
		log.Fatalln(err)
	}

	in := &pb.Request{
		Id:   "1",
		Name: "World",
		Data: "data",
	}
    // 创建一个新的请求
	req := cc.NewRequest(
		"go.vine.helloworld",
		"HelloWorld.Get",
		in,
	)
	rsp := &pb.Response{}
    // 调用请求
	if err := cc.Call(context.TODO(), req, rsp); err != nil {
		log.Fatalln(err)
	}

	fmt.Println(rsp.Reply)
}
```

### 发布消息

```go
func main() {
    ...
    in := &pb.Request{
		Id:   "1",
		Name: "World",
		Data: "data",
	}
    // 发布信息
	if err := cc.Publish(context.TODO(), cc.NewMessage("go.topic", in)); err != nil {
		log.Fatalln(err)
	}
    ...
}
```

### 新建流

```go
func main() {
    ...
    stream, err := cc.Stream(context.TODO(), req)
	if err != nil {
		log.Fatalln(err)
	}
	defer stream.Close()

	go func() {
		// 发送消息
		stream.Send(in)
	}()
	go func() {
		// 接收消息
		rsp := &pb.Request{}
		// 阻塞直到接收到消息
		if err := stream.Recv(rsp); err != nil {

		}
	}()
    ...
}
```

## options

初始化 options:

```go
func main() {
    cc := grpc.NewClient(
		client.Codec(),     // 设置 codec
		client.Selector(),  // 设置 selector
		client.Registry(mdns.NewRegistry()), // 设置 registry
		client.Broker(memory.NewBroker()), // 设置 broker
		client.WithRouter(),  // 设置 router
		client.WrapCall(),    // 设置请求装载器
		client.Wrap(),        // 设置装载器
		client.DialTimeout(), // 设置连接超时时间
		client.ContentType(), // 设置 Content-Type
		client.Backoff(),     // 设置重试机制
		client.PoolSize(),    // 设置连接池容量
		client.PoolTTL(),     // 设置连接池 ttl
		client.StreamTimeout(),  // 设置 stream 超时时间
		client.Retries(),     // 设置错误重试次数
		client.Retry(),   // 设置重试函数
	)
}
```

`NewRequest` 的 options:

```go
func main() {
    req := cc.NewRequest(
		"go.vine.helloworld",
		"HelloWorld.Get",
		in,
		client.WithContentType("application/json"), //  设置请求体的 Content-Type
		client.StreamingRequest(), // 流式请求
	)
}
```

`NewMessage` 的 options:

```go
func main() {
    cc.NewMessage(
		"topic",
		in,
		client.WithMessageContentType("application/json"), // 设置消息的 Content-Type
	)
}
```

`Call` 的 options:

```go
func main() {
    cc.Call(context.TODO(), req, rsp,
		client.WithAddress(),      // 设置服务端地址，跳过通过 Registry 查询服务端的步骤
		client.WithRequestTimeout(), // 请求超时时间
		client.WithStreamTimeout(), // stream 超时时间
		client.WithDialTimeout(),   // 连接时间
		client.WithBackoff(),   // 重试机制
		client.WithCache(),     // 设置缓存时间
		client.WithCallWrapper(), // 设置请求装载器
		client.WithRetries(),   // 设置重试次数
		client.WithRetry(),  // 设置重试函数
		client.WithSelectOption(), // 设置筛选器
	)
}
```

`Publish` 的 Option:
```go
func main() {
    cc.Publish(context.TODO(), cc.NewMessage("go.topic", in),
		client.WithExchange(""), // 设置 exchange
	)
}
```

## http client
http 实现的 client 可以参考 [http](https://github.com/vine-io/vine/blob/master/core/client/http/http_test.go)