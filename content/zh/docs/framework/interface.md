---
title: "接口"
date: 2020-12-29T11:15:20+08:00
weight: 1
description: >
  Vine 是一个可插拔的框架，它利用接口进行抽象和构建基础模块。这使我们能够为分布式系统的概念建立强定义的抽象和可替换的实现。
---

![service内部结构](2020-12-29-08-51-23.png)


## 接口

**Vine** 内置以下的接口列表

- **Auth** - 身份验证和授权
- **broker** - 异步消息
- **client** - 高级请求/响应和消息通知
- **config** - 动态配置
- **codec** - 消息编码和解码
- **debug** - debug 日志，跟踪，统计信息
- **network** - 多云下的网络
- **registry** - 服务发现
- **runtime** - 服务运行时状态
- **selector** - 均衡负载
- **server** - 处理请求和通知
- **store** - 数据存储
- **sync** - 同步，锁和领导选举
- **transport** - 同步通讯
- **tunnel** - vpn 隧道

## Broker
**Broker** 为异步 pub/sub 子通讯提供消息代理的接口。这是事件驱动结构和微服务的基本要求之一。在默认情况下，我们使用 HTTP 协议实现 Broker 接口，以减少依赖。在 [plugins](github.com/lack-io/plugins) 中有许多 Broker 的实现。例如：RabbitMQ，NATS，NSQ等。

## Client

**Client** 提供一个接口来向服务发出请求。和 Server 一样，它构建在其他包上并提供统一的接口。使用 Registry 来查找服务，使用Transport进行同步请求。

## Codec
**Codec** 用于编码和解码消息。这些数据格式可能是 json, protobuf, beson 等。同时还是各种 RPC 数据格式，例如 PROTO-RPC, JSON-RPC, BSON-RPC等。它将编码解码与 Client/Server 分离，并提供继承其他系统的强大方法。

## Config
**Config** 是一个接口。用于从任意数量的源进行动态配置加载，这些源可以合并。大多数系统都主动要求有独立于代码进行更改的配置。通过**Config**接口，可以根据需要动态加载这些值，它还支持各种不同的配置格式。

## Server
**Server** 是编写服务器基础模块。在这里，你可以为服务命名，注册请求处理器，添加中间件等。该服务基于上述包，为服务请求提供统一接口。目前有 gRPC 和 HTTP 两种内置实现。**Server** 还允许你定义多个 Codec 以服务不同的编码消息。

## Store
**Store** 是一个简单的键值对存储接口，用于抽象轻量级的数据存储。我们不是在试图实现一个完整的 sql 语言或者存储，只是仅仅保存服务状态。

## Registry
**Registry** 提供一种服务发现机制，能将服务名称解析为对应的IP地址。它可以由 consul，etcd，zookeeper，dns等支持。服务在启动时注册到 **Registry** 中，并在关闭是注销。服务可能选择提供 TTL，并在这个间隔时间内重新注册，以确保服务在失效时进行清理。

## Selector
**Selector** 是负载均衡的一种抽象，它建立在 *Registry* 上。它允许通过对应的策略选择服务，如随机，循环，最小等算法选择服务。**Client** 在请求时使用 **Selector** 来实现客户端均衡负载。

## Transport
**Transport** 是服务之间同步请求/响应的接口。它类似与 golang 网络包，但提供一个更高级别的抽象，允许我们切换通讯机制，例如 http、rabbitmq、websocket、NATS等。它还支持双向流。