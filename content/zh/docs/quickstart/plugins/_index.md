---
title: "插件中心"
date: 2021-08-27T09:08:02+08:00
draft: false
weight: 6
description: >
  
---
## 概述
**Vine** 构建在 Go 接口之上。因此这些接口的实现是可插拔的。

默认情况下，**Vine** 只提供核心上每个接口的几个实现，但它完全是可插拔的。而额外的实现保存在 [plugins](https://github.com/vine-io/plugins)。

## 添加插件

如果要集成插件，只需将它们链接到单独的文件中并重新生成。
创建 plugins.go 文件并导入所需的插件：
```go
package main

import (
    // etcd registry
    _ "github.com/vine-io/plugins/registry/etcd"
    // nats broker
    _ "github.com/vine-io/plugins/broker/nats"
)
```

通过包含插件文件来构建应用程序：
```bash
go build -o service main.go plugins.go
```

使用插件
```bash
service --registry.default=etcd --broker.default=nats
```

## 插件选项
或者你可以将插件设置在选项中
```go
package main

import (
    "github.com/vine-io/vine"

    // etcd registry
    "github.com/vine-io/plugins/registry/etcd"
    // nats broker
    "github.com/vine-io/plugins/broker/nats"
)

func main() {
    registry := etcd.NewRegistry()
    broker := nats.NewBroker()

    service := vine.NewService(
        vine.Name("greeter"),
        vine.Registry(registry),
        vine.Broker(broker),
    )

    service.Init()

    service.Run()
}
```

## 编写插件

插件是一个建立在 Go 接口上的概念。每个包都维护一个高级接口抽象。只需实现接口并将其作为服务选项传递给它即可.

服务发现接口称为 [Registry](https://pkg.go.dev/github.com/vine-io/vine/core/registry#Registry). 实现此接口的任何内容都可以用作 **Registry**。这同样适用于其他包.

```go
type Registry interface {
	Init(...Option) error
	Options() Options
	Register(context.Context, *Service, ...RegisterOption) error
	Deregister(context.Context, *Service, ...DeregisterOption) error
	GetService(context.Context, string, ...GetOption) ([]*Service, error)
	ListServices(context.Context, ...ListOption) ([]*Service, error)
	Watch(context.Context, ...WatchOption) (Watcher, error)
	String() string
}
```
查阅 [plugins](https://github.com/vine-io/plugins) 可以更好地了解实现细节。

## 插件列表
Registry 插件:
- [etcd](https://github.com/vine-io/plugins/tree/main/registry/etcd)

Broker 插件:
- [nats](https://github.com/vine-io/plugins/tree/main/broker/nats)
- [redis](https://github.com/vine-io/plugins/tree/main/broker/redis)

Dao 插件:
- [mysql](https://github.com/vine-io/plugins/tree/main/dao/mysql)
- [postgresql](https://github.com/vine-io/plugins/tree/main/dao/postgres)
- [sqlite](https://github.com/vine-io/plugins/tree/main/dao/sqlite)

Cache 插件:
- [redis](https://github.com/vine-io/plugins/tree/main/cache/redis)

Sync 插件：
- [etcd](https://github.com/vine-io/plugins/tree/main/sync/etcd)
- [memory](https://github.com/vine-io/plugins/tree/main/sync/memory)

Logger 插件:
- [zap](https://github.com/vine-io/plugins/tree/main/logger/zap)

Config Source 插件：
- [configmap](https://github.com/vine-io/plugins/tree/main/config/source/configmap)
- [etcd](https://github.com/vine-io/plugins/tree/main/config/source/etcd)

Wrapper 类

熔断器:
- [gobreaker](https://github.com/vine-io/plugins/tree/main/wrapper/breaker/gobreaker)
- [hystrix](https://github.com/vine-io/plugins/tree/main/wrapper/breaker/hystrix)

限流器:
- [ratelimiter](https://github.com/vine-io/plugins/tree/main/wrapper/ratelimiter/ratelimiter)
- [uber](https://github.com/vine-io/plugins/tree/main/wrapper/ratelimiter/uber)

链路追踪:
- [opentracing](https://github.com/vine-io/plugins/tree/main/wrapper/trace/opentracing)

数据校验:
- [validator](https://github.com/vine-io/plugins/tree/main/wrapper/validator)