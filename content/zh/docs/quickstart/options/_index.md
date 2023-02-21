---
title: "可选参数"
date: 2020-12-29T14:55:49+08:00
draft: false
weight: 5
description: >

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
## 服务 options
在 **Vine** 中，我们有可以设置多种选项，包括用于身份验证，配置和存储等内容的基础包。你可以使用 `service.Options()` 来访问这些。

auth、config、registry、cache 等包将默认为我们的零依赖插件。可以通过设置环境变量或者命令行参数来配置它们，在执行 `service.Init()` 后生效。
```bash
## or as a flag
go run main.go --cache.default=file
```
## 使用 options
在内部，可以通过选项访问存储：
```go
service := vine.NewService(
    vine.Name("foobar"),
)

service.Init()

store := service.Options().Store
```

> **Vine** 每个内部接口一般都有对应的选项，在插件中，额外的选项通常被保存在 `context.Context` 中。

## 自定义 options
```go
custom := func(s string) vine.Option {
	return func(o *vine.Options) {
		o.Context = context.WithValue(o.Context, s, s)
	}
}
	
vine.NewService(custom("value"))
```
## 所有 options
vine 服务初始化是，支持以下 options

```go
vine.Name(),            // 微服务名称
vine.ID(),              // 微服务 uuid
vine.Version(),         // 微服务版本
vine.Address(),         // 微服务绑定地址
vine.Metadata(),        // 微服务 metadata
vine.Server(),          // 设置内部 Server 模块
vine.Client(),          // 设置内部 Client 模块
vine.Selector(),        // 设置 client selector 
vine.HandleSignal(),    // 是否处理系统信号
vine.Broker(),          // 设置内部 broker 模块
vine.Registry(),        // 设置内部 Registry 模块
vine.RegisterTTL(),     // 服务注册有效时间
vine.RegisterInterval(), // 服务注册间隔，必须小于 ttl
vine.Tracer(),          // 设置 Trace 模块
vine.Dialect(),         // 设置 Dialect 模块
vine.Cmd(),             // 设置 Cmd 模块
vine.Action(),          // 设置 Cmd Action 回调函数
vine.Flags(),           // 添加 Cmd pflag.Flags 
vine.FlagSet(),         // 添加 Cmd pflag.FlagSet
vine.GoFlags(),         // 添加 Cmd flag.Flags 
vine.GoFlagSet(),       // 添加 Cmd flag.FlagSet
vine.WrapHandler(),     // 添加 Server 请求拦截器
vine.WrapClient(),      // 添加 Client 请求拦截器
vine.WrapCall(),        // 添加 Client Call 请求拦截器
vine.WrapSubscriber(),  // 添加 Broker 拦截器
vine.BeforeStart(),     // 追加服务 Start 方法前的回调
vine.BeforeStop(),      // 追加服务 Stop 方法前的回调
vine.AfterStart(),      // 追加服务 Start 方法后的回调
vine.AfterStop(),       // 追加服务 Stop 方法后的回调
```