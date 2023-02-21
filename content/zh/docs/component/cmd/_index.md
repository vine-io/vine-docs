---
title: "命令行参数"
date: 2021-08-27T09:19:36+08:00
draft: false
weight: 200
description: >
---

## 概述

**Vine** 结合 [cobra](https://github.com/spf13/cobra) 提供 `Cmd` 模块，作为服务的命令工具：

```go
type Cmd interface {
	// App The cobra Command within this cmd
	App() *cli.App
	// Init Adds options, parses flags and initialise
	// exits on error
	Init(opts ...Option) error
	// Options set within this command
	Options() Options
}
```

## 使用

```go
package main

import (
	"log"

	"github.com/vine-io/vine/lib/cmd"
)

func main() {
	c := cmd.NewCmd()
	if err := c.Init(); err != nil {
		log.Fatalln(err)
	}
}
```

## options

罗列 `Cmd` 的 options:

```go
func main() {
    c := cmd.NewCmd(
		cmd.Name(),   // 设置 cli 启动名称
		cmd.Server(), // 设置默认 Server 模块
		cmd.Client(), // 设置默认 Client 模块
		cmd.Selector(), // 设置 Client Selector 模块
		cmd.Registry(), // 设置默认 Registry 模块
		cmd.Broker(),  // 设置默认 Broker 模块
		cmd.Tracer(),  // 设置默认 Tracer 模块
		cmd.Dialect(), // 设置默认 Dialect 模块
		cmd.Config(),  // 设置默认 Config 模块
		cmd.Cache(),   // 设置 Cache 模块
		cmd.CliApp(),  // 设置 *cli.App
		cmd.Description(), // 设置 cli 描述信息
	)
}
```

## 服务 cmd

**Vine** 服务启动时初始化 `Cmd` 模块，每个服务支持以下的命令行参数:
| **参数**                                                     | **说明** | **默认值** |
| :---------------------------------------------------------- | :------- | :---------- |
|--broker.default string |              Broker for pub/sub| |
|--cache.default string |               Cache used for key-value storage | |
|--client.content-type string |         Sets the content type for client ||
|--client.default string          |     Client for vine||
|--client.dial-timeout duration     |Sets the client dial timeout||
|--client.grpc.max-idle int  |          Sets maximum idle conns of a pool|  50 |
|--client.grpc.max-recv-msg-size int |   Sets maximum message that client can receive |  104857600|
|--client.grpc.max-send-msg-size int |  Sets maximum message that client can send |  104857600|
|--client.grpc.max-streams int     |    Sets maximum streams on a grpc connections (default 20) ||
|--client.pool-size int     |           Sets the client connection pool size |      |
|--client.pool-ttl duration   |         Sets the client connection pool ttl |      |
|--client.request-timeout duration   |  Sets the client request timeout | |
|--client.retries int   |               Sets the retries ||
|--dao.dialect string    |              Database option for the underlying dao | |
|--dao.dsn string                      |DSN database driver name for underlying dao ||
|--logger.fields strings          |     Sets other fields for logger ||
|--logger.level string     |            Sets the level for logger ||
|--registry.address string      |       Sets the registry addresses ||
|--registry.default string      |       Registry for discovery ||
|--registry.mdns.domain string     |    Sets the domain of mdns| ".vine" |
|--registry.timeout duration    |       Sets the registry request timeout |  3s |
|--selector.default string   |          Selector used to pick nodes for querying ||
|--server.address string   |            Bind address for the server ||
|--server.advertise string   |          Use instead of the server-address when registering with discovery ||
|--server.default string     |          Server for vine |    |
|--server.grpc.content-type string   |  Sets the content type for grpc protocol | "application/grpc"|
|--server.grpc.max-msg-size int   |     Sets maximum message size that server can send receive | 104857600 |
|--server.id string       |             Id of the server||
|--server.metadata strings    |         A list of key-value pairs defining metadata ||
|--server.name string        |          Name of the server||
|--server.register-interval duration  | Register interval ||
|--server.register-ttl duration      |  Registry TTL||
|--tracer.address string      |         Comma-separated list of tracer addresses||
|--tracer.default string        |       Trace for vine |          |

# 添加额外参数
**Vine** 的 `Cmd` 是基于 [cobra](https://github.com/spf13/cobra) 构建的，因此如果需要添加额外的参数，方法和 cobra 一样:

```golang
func main() {
	c := cmd.NewCmd()

	// 添加 other 参数， --other=xxx
	c.App().PersistentFlags().String("other", "", "Sets the other parameters")

	if err := c.Init(); err != nil {
		log.Fatalln(err)
	}
}
```
添加子命令
```golang
func main() {
	c := cmd.NewCmd()

	// 添加子命令
	// go run main.go sub
	// > execute sub command
	c.App().AddCommand(&cobra.Command{
		Use:   "sub",
		Short: "command for test",
		Run: func(cmd *cobra.Command, args []string) {
			cmd.Println("execute sub command")
		},
	})

	if err := c.Init(); err != nil {
		log.Fatalln(err)
	}
}
```

# viper 
[viper](https://github.com/spf13/viper) 可以读取不同格式参数文件，例如 json、yaml、toml 等。同时可以和 cobra 库结合。**Vine** 引入 viper 库实现同时支持读取命令行参数和配置文件，详情可见 [config](https://pkg.go.dev/github.com/vine-io/vine/util/config)。
```bash
go run main.go default
```
输出支持的配置参数格式
```bash
broker:
    default: ""
cache:
    default: ""
...
```
可以通过设置，在启动服务时使命令行参数和配置文件同时生效。
先启动服务：
```golang
import (
	"github.com/vine-io/vine"
	uc "github.com/vine-io/vine/util/config"
)

func main() {

	// 配置参数文件名称
	uc.SetConfigName("config.yml")
	// 配置参数文件格式，yaml、json、toml
	uc.SetConfigType("yaml")
	// 指定在哪个目录下查找配置文件，支持多个路径
	uc.AddConfigPath(".")
	s := vine.NewService()

	s.Init()

	s.Run()
}
```
编辑配置文件
```yaml
server:
  name: cmdtest
  address: 127.0.0.1:35000
```
启动服务
```golang
> go run cmd/main.go --server.id=cmdtest-id
2023-02-21 10:58:30 file=vine/service.go:173 level=info Starting [service] cmdtest
2023-02-21 10:58:30 file=vine/service.go:174 level=info service [version] latest
2023-02-21 10:58:30 file=grpc/grpc.go:911 level=info Server [grpc] Listening on 127.0.0.1:35000
2023-02-21 10:58:30 file=grpc/grpc.go:752 level=info Registry [mdns] Registering node: cmdtest-cmdtest-id
2023-02-21 10:58:30 file=mdns/mdns_registry.go:260 level=info [mdns] registry create new service with ip=127.0.0.1 port=35000 for: 127.0.0.1
```
服务启动读取参数信息的优先级从高到低依次为: 配置文件 -> 命令行参数 -> 可选参数。