---
title: "插件"
date: 2020-12-29T14:56:43+08:00
draft: false
weight: 4
description: >
  **Vine** 是一个可插拔的框架。
---

## 概述
**Vine** 构建在 Go 接口之上。因此这些接口的实现是可插拔的。

默认情况下，**Vine** 只提供核心上每个接口的几个实现，但它完全是可插拔的。而额外的实现保存在 [plugins](https://github.com/lack-io/plugins)。

## 添加插件

如果要集成插件，只需将它们链接到单独的文件中并重新生成。
创建 plugins.go 文件并导入所需的插件：
```go
package main

import (
    // consul registry
    _ "github.com/lack-io/plugins/registry/consul"
    // rabbitmq transport
    _ "github.com/lack-io/plugins/transport/rabbitmq"
    // kafka broker
    _ "github.com/lack-io/plugins/broker/kafka"
)
```

通过包含插件文件来构建应用程序：
```bash
go build -o service main.go plugins.go
```

使用插件
```bash
service --registry=consul --transport=nats --broker=kafka
```
或者使用环境变量
```bash
VINE_REGISTRY=consule VINE_TRANSPORT=rabbitmq VINE_BROKER=kafka service
```

## 插件选项
或者你可以将插件设置在选项中
```go
package main

import (
    vine "github.com/lack-io/vine/service"

    // consul registry
    "github.com/lack-io/plugins/registry/consul"
    // rabbitmq transport
    "github.com/lack-io/plugins/transport/rabbitmq"
    // kafka broker
    "github.com/lack-io/plugins/broker/kafka"
)

func main() {
    registry := consul.NewRegistry()
    broker := kafka.NewBroker()
    transport := rabbitmq.NewTransport()

    service := vine.NewService(
        vine.Name("greeter"),
        vine.Registry(registry),
        vine.Broker(broker),
        vine.Transport(transport),
    )

    service.Init()

    service.Run()
}
```

## 编写插件

插件是一个建立在 Go 接口上的概念。每个包都维护一个高级接口抽象。只需实现接口并将其作为服务选项传递给它即可.

服务发现接口称为 [Registry](https://pkg.go.dev/github.com/lack-io/vine/service/registry#Registry). 实现此接口的任何内容都可以用作 **Registry**。这同样适用于其他包.

```go
type Registry interface {
	Init(...Option) error
	Options() Options
	Register(*Service, ...RegisterOption) error
	Deregister(*Service, ...DeregisterOption) error
	GetService(string, ...GetOption) ([]*Service, error)
	ListServices(...ListOption) ([]*Service, error)
	Watch(...WatchOption) (Watcher, error)
	String() string
}
```
查阅 [plugins](https://github.com/lack-io/plugins) 可以更好地了解实现细节。