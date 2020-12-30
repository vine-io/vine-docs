---
title: "订阅发布"
date: 2020-12-29T14:59:08+08:00
draft: false
weight: 9
description: >
  用 **Broker** 构建微服务的发布订阅事件驱动
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

默认情况下，vine 实现点对点 http 代理，但可以通过 [plugins](https://github.com/lack-io/plugins) 替换实现。

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
完整实例可以看 [example/pubsub](https://github.com/lack-io/vine-example/tree/main/pubsub)