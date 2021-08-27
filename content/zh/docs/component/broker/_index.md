---
title: "订阅发布"
date: 2020-12-29T14:59:08+08:00
draft: false
weight: 20
description: >
---

## 概述
微服务是一种事件驱动的体系结构模式，因此 **Vine** 使用消息代理接口构建异步消息的概念。它可为用户无缝地运行 protobuf 类型，并自动编码和解码消息。

```go
// Broker is an interface used for asynchronous messaging.
type Broker interface {
	Init(...Option) error
	Options() Options
	Address() string
	Connect() error
	Disconnect() error
	Publish(topic string, m *Message, opts ...PublishOption) error
	Subscribe(topic string, h Handler, opts ...SubscribeOption) (Subscriber, error)
	String() string
}
```

默认情况下，vine 实现点对点 http 代理，但可以通过 [plugins](https://github.com/vine-io/plugins) 替换实现。

## 发布消息
使用 topic 名称和服务客户端创建一个新的发布者
```go
p := vine.NewEvent("events", service.Client())
```
发布 proto 消息
```go
p.Publish(context.TODO(), &proto.Event{Name: "event"})
```
## 订阅
创建消息处理程序。它的签名应该是 `func(context.Context, v interface{}) error`
```go
func ProcessEvent(ctx context.Context, event *proto.Event) error {
    fmt.Printf("Got event %+v\n", event)
    return nil
}
```
使用 topic 注册消息处理程序
```go
vine.RegisterSubscriber("events", ProcessEvent)
```
完整实例可以看 [example/pubsub](https://github.com/vine-io/vine-example/tree/main/pubsub)

## 单独使用 Broker 
`Broker` 也可以单独使用：
```go
package main

import (
	"fmt"
	"time"

	"github.com/vine-io/vine/service/broker"
	log "github.com/vine-io/vine/service/logger"
)

func main() {
	topic := "go.vine.topic.foo"

	b := broker.NewBroker()

	if err := b.Init(); err != nil {
		log.Fatalf("Broker Init error: %v", err)
	}
	if err := b.Connect(); err != nil {
		log.Fatalf("Broker Connect error: %v", err)
	}

	go func() {
		// receive message from broker
		b.Subscribe(topic, func(p broker.Event) error {
			fmt.Println("[sub] received message:", string(p.Message().Body), "header", p.Message().Header)
			return nil
		})
	}()

	go func() {
		<-time.After(time.Second * 1)
		// publish message to broker
        b.Publish(topic, &broker.Message{Header: map[string]string{"a": "b"}, Body: []byte("hello world")})
	}()

    time.Sleep(time.Second * 2)
    
    b.Disconnect()
}
```