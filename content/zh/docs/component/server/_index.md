---
title: "内部服务"
date: 2020-12-29T15:00:10+08:00
draft: false
weight: 30
description: >
---

## 概述

`Server` 是微服务的核心模块，它对外提供接口，根据不同的实现，提供相应类型的接口。目前内部支持:

- grpc
- http

`Server` 依赖图

{{< figure src="2021-09-03-11-20-03.png" style="text-align:center;" height="30%" width="30%" >}}

以下是 `Server` 模块的内部方法。

```go
// Server is a simple vine server abstraction
type Server interface {
	// 初始化
	Init(...Option) error
	// 返回 Options
	Options() Options
	// 注册 Handler
	Handle(Handler) error
	// 创建一个新的 Handler
	NewHandler(interface{}, ...HandlerOption) Handler
	// 创建一个新的 Subscriber
	NewSubscriber(string, interface{}, ...SubscriberOption) Subscriber
	// 注册 Subscriber
	Subscribe(Subscriber) error
	// 启动服务
	Start() error
	// 停止服务
	Stop() error
	// Server 接口类型
	String() string
}
```

## 使用方法

### 启动一个 grpc 服务

```go
package main

import (
	"log"
	"os"
	"os/signal"

	"github.com/vine-io/vine/core/broker/memory"
	"github.com/vine-io/vine/core/registry/mdns"
	"github.com/vine-io/vine/core/server"
	"github.com/vine-io/vine/core/server/grpc"
	usignal "github.com/vine-io/vine/util/signal"
)

func main() {
	// 新建 gRPC 服务
	s := grpc.NewServer(
		server.Name("helloworld"),
		server.Address(":9000"),
		server.Broker(memory.NewBroker()),
		server.Registry(mdns.NewRegistry()),
	)
	// 初始化
	if err := s.Init(); err != nil {
		log.Fatalf("grpc init: %v", err)
	}
	// 启动服务, (非阻塞)
	if err := s.Start(); err != nil {
		log.Fatalf("grpc start: %v", err)
	}
	//
	ch := make(chan os.Signal, 1)
	signal.Notify(ch, usignal.Shutdown()...)

	select {
	// wait on kill signal
	case <-ch:
	}

    // 停止服务
	if err := s.Stop(); err != nil {
		log.Fatalf("grpc stop: %v", err)
	}
}
```

### 注册 Handler

```go
...

type HelloImpl struct {

}

var _ proto.Message = (*Request)(nil)
type Request struct {
	Name string
}

func (r *Request) Reset() {
	r = &Request{}
}

func (r Request) String() string {
	return ""
}

func (r Request) ProtoMessage() {

}


type Response struct {
	Name string
}

func (h *HelloImpl) Get(ctx context.Context, r *Request, rsp *Response) error {
	rsp.Name = r.Name
	return nil
}
...

func main() {
	...
	if err := s.Init(); err != nil {
		log.Fatalf("grpc init: %v", err)
	}

	h := &HelloImpl{}
	opts := []server.HandlerOption{
		api.WithEndpoint(&api.Endpoint{
			Name:        "HelloWorld.Get",
			Description: "HelloWorld.Get",
			Path:        []string{"/api/v1/get"},
			Method:      []string{"GET"},
			Body:        "*",
			Handler:     "rpc",
		}),
	}
	if err := s.Handle(s.NewHandler(h, opts...)); err != nil {
		log.Fatalf("register handler: %v", err)
	}
	...
}
```

### 注册 Subscriber

```go
// Alternatively a function can be used
func subEv(ctx context.Context, event *Request) error {
	md, _ := metadata.FromContext(ctx)
	log.Println("[pubsub.2] Received event %+v with metadata %+v\n", event, md)
	// do something with event
	return nil
}

func main() {
	...
	if err := s.Init(); err != nil {
		log.Fatalf("grpc init: %v", err)
	}

	if err := s.Subscribe(s.NewSubscriber("get.topic", subEv, server.SubscriberQueue("sub"))); err != nil {
		log.Fatalf("register subscribe: %v", err)
	}
	...
}
```

## options

使用

```go
func main() {
	s := grpc.NewServer(server.Name("name"))
}
```

`Server` 创建和初始化 options

```go
func  main() {
	grpc.NewServer(
		// 设置服务名称
		server.Name(),
		// 设置公共 IP 地址
		server.Advertise(),
		// 设置服务绑定地址，如果 Advertise 不为空，优先选择 Advertise
		server.Address(),
		// 设置服务 id
		server.Id(),
		// 设置服务 版本
		server.Version(),
		// 设置服务 context.Context, 保存额外的值
		server.Context(),
		// 设置服务序列化
		server.Codec(),
		// 设置服务依赖的 Broker
		server.Broker(memory.NewBroker()),
		// 设置服务依赖的 Registry
		server.Registry(mdns.NewRegistry()),
		// 添加 Subscriber 处理器的装载器
		server.WrapSubscriber(),
		// 添加 Handler 装载器
		server.WrapHandler(),
		// 设置服务注册时的 ttl
		server.RegisterTTL(),
		// 设置服务注册间隔时间
		server.RegisterInterval(),
		// 设置内部 sync.WaitGroup
		server.Wait(),
		// 设置服务元数据
		server.Metadata(),
		// 设置服务启动时注册到 Registry 的检测函数
		server.RegisterCheck(func(ctx context.Context) error {
			return nil
		}),
		// 设置服务 Router
		server.WithRouter(),
	)
}
```

创建 Handler 的 options

```go
func main() {
	s.NewHandler(h,
		server.InternalHandler(), // 内部 handler
		api.WithEndpoint(),   // 添加 api 信息
		server.OpenAPIHandler(), // 添加 swagger 信息
	)
}
```

创建 Subscriber 的 options

```go
func main() {
	s.NewSubscriber("topic", subEv,
		server.InternalSubscriber(), // 内部 internal
		server.SubscriberQueue(),   // 设置 subscriber 队列
		server.SubscriberContext(), // subscriber 内部 context.Context
	)
}
```

## gRPC 结合 http

`Server` 的 gRPC 实现可以同时提供 gRPC 和 http 服务:

```go
import (
	"net/http"

	"github.com/gin-gonic/gin"
	membroker "github.com/vine-io/vine/core/broker/memory"
	"github.com/vine-io/vine/core/registry/memory"
	"github.com/vine-io/vine/core/server"
	"github.com/vine-io/vine/core/server/grpc"
)

func main() {
	reg := memory.NewRegistry()
	bro := membroker.NewBroker()

	mux := gin.New()
	mux.GET("/", func(ctx *gin.Context) {
		ctx.JSON(http.StatusOK, "hello world")
		return
	})
	s := grpc.NewServer()
	s.Init(grpc.HttpHandler(mux), server.Registry(reg), server.Broker(bro))

	s.Start()

	select {}
}
```

> grpc 内置 prometheus metrics 和 golang http prof 接口

## http 实现

```go

import (
	"net/http"

	membroker "github.com/vine-io/vine/core/broker/memory"
	"github.com/vine-io/vine/core/registry/memory"
	"github.com/vine-io/vine/core/server"
	vhttp "github.com/vine-io/vine/core/server/http"
	log "github.com/vine-io/vine/lib/logger"
)

func main() {
	reg := memory.NewRegistry()
	bro := membroker.NewBroker()

	// create server
	srv := vhttp.NewServer(server.Registry(reg), server.Broker(bro))

	// create server mux
	mux := http.NewServeMux()
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte(`hello world`))
	})

	// create handler
	hd := srv.NewHandler(mux)

	// register handler
	if err := srv.Handle(hd); err != nil {
		log.Fatal(err)
	}

	// start server
	if err := srv.Start(); err != nil {
		log.Fatal(err)
	}

	select {}
}
```
