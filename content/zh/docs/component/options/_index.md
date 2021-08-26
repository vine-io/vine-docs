---
title: "选项"
date: 2020-12-29T14:55:49+08:00
draft: false
weight: 4
description: >
  **Vine** 使用可变选项模型来设计包的创建和初始化传递参数，以及作为方法的可选参数。这为扩展跨插件的选项使用提供了灵活性
---

## 概述
创建新服务时，你可以选择传递其他参数，例如设置名称，版本，Broker，Registry 或者存储，以便与所有其他内部实现一起使用。
选项通常定义如下：

```go
type Options struct {
    Name        string
    Version     string
    Broker      broker.Broker
    Registry    registry.Registry
}


type Option func(*Options)

// set the name
func Name(n string) Option {
    return func(o *Options) {
        o.Name = n
    }
}

// set the broker
func Broker(b broker.Broker) Option {
    return func(o *Options) {
        o.Broker = b
    }
}
```
然后这安装如下方式设置这些选项
```go
service := vine.NewService(
    vine.Name("foobar"),
    vine.Broker(broker),
)
```
## 服务选项
在 **Vine** 中，我们有许多选项可以设置，包括用于身份验证，配置和存储等内容的基础包。你可以使用 `service.Options()` 来访问这些。

auth、config、registry、store 等包将默认为我们的零依赖插件。可以通过设置环境变量或者命令行参数来配置它们，在执行 `service.Init()` 后生效。
```bash
## as an env vars
VINE_STORE=file go run main.go

## or as a flag
go run main.go --store=file
```
然后在内部，可以通过选项访问存储：
```go
service := vine.NewService(
    vine.Name("foobar"),
)

service.Init()

store := service.Options().Store
```

> **Vine** 每个内部接口一般都有对应的选项，在插件中，额外的选项通常被保存在 `context.Context` 中。