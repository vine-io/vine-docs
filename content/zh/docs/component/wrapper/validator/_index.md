---
title: "数据校验"
date: 2021-08-27T09:30:56+08:00
draft: false
weight: 3
description: >
---

## 简介
通过 wrapper 的特性，我们可以对 `Client` 的输出和对 `Server` 输入的数据进行合法性校验。

## 实现
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
	verrs "github.com/vine-io/vine/lib/errors"
	log "github.com/vine-io/vine/lib/logger"
	"github.com/vine-io/vine/lib/trace/memory"
	"github.com/vine-io/vine/util/wrapper"
)

type hello struct{}

func (h hello) Echo(ctx context.Context, request *pb.Request, response *pb.Response) error {
	response.Result = request.Name
	return nil
}

func main() {
	s := vine.NewService(
		vine.Name("helloworld"),
		vine.WrapHandler(HandlerValidatorWrapper()),
	)

	s.Init()

	pb.RegisterHelloHandler(s.Server(), &hello{})

	go func() {
		time.Sleep(time.Second)
		cli := grpc.NewClient(client.WrapCall(CallValidatorWrapper()))
		cli = wrapper.TraceCall(s.Name(), memory.NewTracer(), cli)
		cc := pb.NewHelloService(s.Name(), cli)
		rsp, err := cc.Echo(context.TODO(), &pb.Request{""})
		if err != nil {
			log.Fatal(err)
		}
		fmt.Println(rsp)
	}()

	if err := s.Run(); err != nil {
		log.Fatal(err)
	}
}

type Validator interface {
	Validate() error
}

func CallValidatorWrapper() client.CallWrapper {
	return func(fn client.CallFunc) client.CallFunc {
		return func(ctx context.Context, node *registry.Node, req client.Request, rsp interface{}, opts client.CallOptions) error {
			if v, ok := req.Body().(Validator); ok {
				if err := v.Validate(); err != nil {
					return verrs.BadRequest(req.Service(), err.Error())
				}
			}
			return fn(ctx, node, req, rsp, opts)
		}
	}
}

func HandlerValidatorWrapper() server.HandlerWrapper {
	return func(fn server.HandlerFunc) server.HandlerFunc {
		return func(ctx context.Context, req server.Request, rsp interface{}) error {
			if v, ok := req.Body().(Validator); ok {
				if err := v.Validate(); err != nil {
					return verrs.BadRequest(req.Service(), err.Error())
				}
			}
			return fn(ctx, req, rsp)
		}
	}
}
```

