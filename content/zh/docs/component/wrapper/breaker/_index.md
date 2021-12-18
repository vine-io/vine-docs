---
title: "断路器"
date: 2021-08-27T09:33:11+08:00
draft: false
weight: 6
description: >
---

## 什么是断路器
> 断路器（又称熔断器，Circuit Breaker，简称CB），广泛使用于工业生产和日常生活中，主要功能是合上和断开回路（ON/OFF POWER）。别名:空气开关、保险掣、无熔丝开关。断路器会在短路和严重超载的情况下切断电路，从而有效的保护回路中的电器。-- 维基百科

雪崩效应: 微服务之间的数据交互是通过远程调用来完成。服务A调用服务B，服务B调用服务C。如果某一时间调用链路上的一个服务不可用，但是其他服务还在不断调用这个服务，或者不断的重试，就会导致系统资源不断被占用，出现级联故障，从而造成这个系统可不用。

`breaker` 的出现正是为了解决这个问题，当某个服务不可用时，调用端会开启熔断检测，当请求的错误达到一定阈值的时候，开启熔断关闭。这时所有调用这个服务的请求直接报错，避免出现级联故障。同时每个一段时间检测服务请求状态，如果服务请求成功，关闭熔断，链路恢复。它实际是特殊的服务降级方式，是一种软件高并发解决方案。

![](2021-09-08-10-04-36.png)

## 使用
**Vine** 通过 wrapper 特性实现熔断器功能，在 `Client Call` 请求中添加熔断 wrapper。
```go
package main

import (
	"context"
	"fmt"
	"os"
	"time"

	"github.com/sony/gobreaker"
	pb "github.com/vine-io/examples/wrapper/pb"
	bk "github.com/vine-io/plugins/wrapper/breaker/gobreaker"
	"github.com/vine-io/vine"
	log "github.com/vine-io/vine/lib/logger"
)

type hello struct{}

func (h hello) Echo(ctx context.Context, request *pb.Request, response *pb.Response) error {
	response.Result = request.Name
	return nil
}

func main() {
	bs := gobreaker.Settings{
		Name:          "breaker",
		MaxRequests:   10,
		Interval:      time.Second * 10,
		Timeout:       time.Second * 15,
		ReadyToTrip: func(counts gobreaker.Counts) bool {
			failureRatio := float64(counts.TotalFailures) / float64(counts.Requests)
			return counts.Requests >= 3 && failureRatio >= 0.6
		},
		OnStateChange: func(name string, from gobreaker.State, to gobreaker.State) {
			log.Info("%s %s => %s", name, from.String(), to.String())
		},
	}
	breaker := bk.NewCustomClientWrapper(bs, bk.BreakService)

	s := vine.NewService(
		vine.Name("helloworld"),
		vine.WrapClient(breaker),
	)

	s.Init()

	pb.RegisterHelloHandler(s.Server(), &hello{})

	go func() {
		time.Sleep(time.Second)
		cc := pb.NewHelloService(s.Name(), s.Client())
		rsp, err := cc.Echo(context.TODO(), &pb.Request{""})
		if err != nil {
			log.Fatal(err)
		}
		fmt.Println(rsp)
		os.Exit(0)
	}()

	if err := s.Run(); err != nil {
		log.Fatal(err)
	}
}
```