---
title: "服务注册发现"
date: 2020-12-29T14:57:27+08:00
draft: false
weight: 1
description: >
---
## 概述
`服务注册发现`模块是微服务的核心。服务端需要它来提供注册服务，登录服务自身信息。客户端需要它来根据名称查找服务地址。

**Vine** 提供一个通用的 `Registry` 接口，描述 `服务注册发现` 模块的行为。
```go
type Registry interface {
	Init(...Option) error // ------------------------------- 模块初始化
	Options() Options // ----------------------------------- 模块的配置信息
	Register(context.Context, *Service, ...RegisterOption) error // --------- 注册服务
	Deregister(context.Context, *Service, ...DeregisterOption) error // ----- 注销服务
	GetService(context.Context,string, ...GetOption) ([]*Service, error) //- 根据名称查找服务
	ListServices(context.Context, ...ListOption) ([]*Service, error) // ----- 查询所有服务
	Watch(context.Context, ...WatchOption) (Watcher, error) // -------------- 监听服务变化
	String() string // ------------------------------------- 查询实现 Registry 接口的具体类型
}
```
## 使用
在此我们提供一个完整的代码来介绍 `Registry` 的具体使用方式:

### 初始化
```go
package main

import (
	"github.com/vine-io/vine/core/registry"
	"github.com/vine-io/vine/core/registry/mdns"
)

func main() {
	// 创建新的 Registry
	r := mdns.NewRegistry()
	// 初始化
	if err := r.Init(); err != nil {
		log.Fatalln(err)
	}
}
```
### 注册和注销服务
```go
func main() {
	// 创建新的服务
	svc := &registry.Service{
		Name:     "go.vine.test",   // 服务名称，唯一值
		Version:  "v1.0.0",         // 服务版本
		Metadata: map[string]string{"Content-Type": "application/json"},  // 元数据
		Endpoints: []*registry.Endpoint{        // 服务接口
			{
				Name:     "",
				Request:  nil,
				Response: nil,
				Metadata: nil,
			},
		},
		Nodes: []*registry.Node{     // 该服务下的节点信息, 节点的 ID 必须是不同的，当一个 `Registry` 中多次注册相同服务时，服务的该字段就会合并
			{
				Id:       uuid.New().String(),
				Address:  "127.0.0.1:11500",
				//Port:     11500,
				Metadata: map[string]string{"os": "linux"},
			},
		},
		TTL:  30,  // 服务过期时间，单位秒
		Apis: nil, // swagger 信息
	}

	// 注册服务
	ctx := context.TODO()
	if err := r.Register(ctx, svc); err != nil {
		log.Fatalln(err)
	}

	// 注销服务
	if err := r.Deregister(ctx, svc); err != nil {
		log.Fatalln(err)
	}
}
```

### 查询服务
```go
func main() {
	// 查询所有服务
	list, err := r.ListServices()
	if err != nil {
		log.Fatalln(err)
	}
	for _, item := range list {
		fmt.Println(item.Name)
	}

	// 查询单个服务
	ctx := context.TODO()
	list, err = r.GetService(ctx, "go.vine.test")
	if err != nil {
		log.Fatalln(err)
	}
	for _, item := range list {
		fmt.Println(item.Name, len(item.Nodes))
	}
}
```
> ListService() 方法获取的结果，数据是不完整的，只含有包括服务名称在内的少量信息。

### 监听服务
```go
func main() {
	// 启动一个监听器
	ctx := context.TODO()
	watcher, err := r.Watch(ctx, registry.WatchService("go.vine.test"))
	if err != nil {
		log.Fatalln(err)
	}
	// 停止监听器
	defer watcher.Stop()
	go func() {
		for {
			e, err := watcher.Next() // 这里会阻塞，直到返回事假
			if err != nil {
				return
			}
			fmt.Printf("%d: %s, %s\n",  e.Timestamp, e.Action, e.Service.Name)
		}
	}()
}
```
### 替换服务的 `Registry`
**Vine** 服务默认 `Registry` 为 `mdns`。尝试去替换成 `memory`。
```go
package main

import (
	"github.com/vine-io/vine"
	"github.com/vine-io/vine/core/registry/memory"
)

func main() {
	mr := memory.NewRegistry()
	vine.NewService(vine.Registry(mr))
}
```
## options
`Registry` 接口的几个方法都支持 Options。

创建 `NewRegistry(opts...)` 和 初始化 `Init(opts...)`
```go
memory.NewRegistry(
	// Registry 的 ip 地址
	registry.Addrs(addrs ...string),
	// 连接超时时间
	registry.Timeout(t time.Duration),
	// 安全通讯
	registry.Secure(b bool),
	// 安全通讯所需证书信息
	registry.TLSConfig(t *tls.Config),
)
```
注册服务 `Register(svc, opts...)`
```go
memory.Register(svc,
	// 服务过期时间
	registry.RegisterTTL(ttl int64), 
	// 上下文信息
	registry.RegisterContext(ctx context.Context),
)
```
注销服务 `Deregister(svc, opts...)`
```go
memory.Deregister(svc,
	registry.DeregisterContext(ctx context.Context),
)
```
查询所有服务 `ListServices(opts...)`
```go
memory.ListServices(svc,
	registry.ListServicesContext(ctx context.Context),
)
```
根据名称获取服务 `GetService(name, opts...)`
```go
memory.GetService(svc,
	registry.GetServiceContext(ctx context.Context),
)
```
监听服务 `Watch(opts...)`
```go
memory.Watch(svc,
    // 监听单个服务
	registry.WatchService(name string),
	registry.WatchServiceContext(ctx context.Context),
)
```
## 插件
**Vine** 目前自带的 `Registry` 实现有:
- memory 
- mdns

第三方的实现请参考 [registry](https://github.com/vine-io/plugins/tree/main/registry)
### etcd
```go
package main

import (
	"github.com/vine-io/vine"
	"github.com/vine-io/vine/lib/cmd"
	"github.com/vine-io/plugins/registry/etcd"
)
	
func main() {
	er := etcd.NewRegistry()
	vine.NewService(vine.Registry(er))
}
```

## 服务启动
**Vine** 服务以插件的方式，注册多种实现，用户可以再服务启动时选择喜欢的类型。
```bash
./helloworld --registy.default=etcd --registry.address=127.0.0.1:2379
```