---
title: "链路追踪"
date: 2021-08-27T09:29:36+08:00
draft: false
weight: 2
description: >
---
## 什么是链路追踪
链路追踪，全称分布式链路追踪。在微服务架构下，系统由大量服务组成，每个服务可能是由不同的团队开发、可能使用不同的编程语言来实现、有可能布在了几千台服务器，横跨多个不同的数据中心…例如一次请求往往会涉及到多个服务，在系统发生故障的时候，快速定位和解决问题，就需要追踪服务请求序列。因此，分析性能问题的工具以及理解系统的行为变得很重要。链路追踪正是用于解决这个问题。

**Vine** 中通过 wrapper 实现链路追踪。

## 实例
我们提供一个简单的代码实例，来说明链路追踪的工作方式:
```go
package main

import (
	"context"
	"fmt"
	"time"

	pb "github.com/vine-io/examples/wrapper/pb"
	"github.com/vine-io/vine"
	"github.com/vine-io/vine/core/client"
	"github.com/vine-io/vine/core/client/grpc"
	"github.com/vine-io/vine/core/registry"
	"github.com/vine-io/vine/core/server"
	log "github.com/vine-io/vine/lib/logger"
	"github.com/vine-io/vine/lib/trace"
	"github.com/vine-io/vine/lib/trace/memory"
	"github.com/vine-io/vine/util/wrapper"
)

type hello struct {
}

func (h hello) Echo(ctx context.Context, request *pb.Request, response *pb.Response) error {
	ctx, span := trace.DefaultTracer.Start(ctx, "echo")
	defer trace.DefaultTracer.Finish(span)
	
	response.Result = request.Name
	return nil
}

func main() {
	s := vine.NewService(
		vine.WrapHandler(HandlerWrapper()),
	)

	s.Init()

	pb.RegisterHelloHandler(s.Server(), &hello{})

	go func() {
		time.Sleep(time.Second)
        // grpc 加载 trace wrapper
		cli := grpc.NewClient(client.WrapCall(CallWrapper()))
		cli = wrapper.TraceCall(s.Name(), memory.NewTracer(), cli)
		cc := pb.NewHelloService(s.Name(), cli)
		cc.Echo(context.TODO(), &pb.Request{"Client"})
	}()

	if err := s.Run(); err != nil {
		log.Fatal(err)
	}
}

func CallWrapper() client.CallWrapper {
	return func(fn client.CallFunc) client.CallFunc {
		return func(ctx context.Context, node *registry.Node, req client.Request, rsp interface{}, opts client.CallOptions) error {
			traceID, parentID, ok := trace.FromContext(ctx)
			if ok {
				fmt.Printf("call: tarceID=%s parentID=%s\n", traceID, parentID)
			}
			return fn(ctx, node, req, rsp, opts)
		}
	}
}

func HandlerWrapper() server.HandlerWrapper {
	return func(fn server.HandlerFunc) server.HandlerFunc {
		return func(ctx context.Context, req server.Request, rsp interface{}) error {
			traceID, parentID, ok := trace.FromContext(ctx)
			if ok {
				fmt.Printf("handle: tarceID=%s parentID=%s\n", traceID, parentID)
			}
			return fn(ctx, req, rsp)
		}
	}
}
```
新建链路
```go
ctx = trace.ToContext(ctx, uuid.NewString(), uuid.NewString())
```
链路调用
```go
// 新建链路
ctx, span := trace.Start(ctx, "echo")
// 停止 span
defer trace.Finish(span)
```
捕获链路
```go
traceID, parentID, ok := trace.FromContext(ctx)
if ok {
	fmt.Printf("call: tarceID=%s parentID=%s\n", traceID, parentID)
}
```
