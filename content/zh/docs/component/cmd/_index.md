---
title: "命令行参数"
date: 2021-08-27T09:19:36+08:00
draft: false
weight: 200
description: >
---

## 概述

**Vine** 结合 [cli](https://github.com/vine-io/cli) 提供 `Cmd` 模块，作为服务的命令工具：

```go
type Cmd interface {
	// App The cli app within this cmd
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

	c.App().RunAndExitOnError()
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
| 参数 | 说明 | 默认值 | 环境换脸 |
|---|---|---|---|---|
|--client string| Client for vine; |rpc| [$VINE_CLIENT]
|--client-request-timeout string | Sets the client request timeout. e.g 500ms, 5s, 1m. |Default: 5s | [$VINE_CLIENT_REQUEST_TIMEOUT]
|--client-retries int | Sets the client retries. |Default: 1 (default: 1) |[$VINE_CLIENT_RETIES]
|--client-pool-size int | Sets the client connection pool size. | Default: 1 (default: 0) | [$VINE_CLIENT_POOL_SIZE]
|--client-pool-ttl string | Sets the client connection pool ttl. e.g 500ms, 5s, 1m. | Default: 1m | [$VINE_CLIENT_POOL_TTL]
|--register-ttl int | Register TTL in seconds | (default: 60) | [$VINE_REGISTER_TTL]
|--register-interval int | Register interval in seconds | (default: 30) | [$VINE_REGISTER_INTERVAL]
|--server string | Server for vine; |rpc |[$VINE_SERVER]
|--server-name string | Name of the server. go.vine.svc.example ||[$VINE_SERVER_NAME]
|--server-version string | Version of the server. 1.1.0 ||[$VINE_SERVER_VERSION]
|--server-id string | Id of the server. Auto-generated if not specified|| [$VINE_SERVER_ID]
|--server-address string | Bind address for the server. 127.0.0.1:8080 ||[$VINE_SERVER_ADDRESS]
|--server-advertise string | Use instead of the server-address when registering with discovery. 127.0.0.1:8080 ||[$VINE_SERVER_ADVERTISE]
|--server-metadata strings | A list of key-value pairs defining metadata. version=1.0.0 ||[$VINE_SERVER_METADATA]
|--broker string | Broker for pub/sub. http, nats|| [$VINE_BROKER]
|--broker-address string | Comma-separated list of broker addresses ||[$VINE_BROKER_ADDRESS]
|--registry string | Registry for discovery. memory, mdns ||[$VINE_REGISTRY]
|--registry-address string | Comma-separated list of registry addresses ||[$VINE_REGISTRY_ADDRESS]
|--selector string | Selector used to pick nodes for querying|| [$VINE_SELECTOR]
|--dao-dialect string | Database option for the underlying dao|| [$VINE_DAO_DIALECT]
|--dao-dsn string | DSN database driver name for underlying dao ||[$VINE_DSN]
|--config string | The source of the config to be used to get configuration ||[$VINE_CONFIG]
|--cache string | Cache used for key-value storage|| [$VINE_CACHE]
|--cache-address string | Comma-separated list of cache addresses ||[$VINE_CACHE_ADDRESS]
|--tracer string | Tracer for distributed tracing, e.g. memory, jaeger|| [$VINE_TRACER]
|--tracer-address string | Comma-separated list of tracer addresses|| [$VINE_TRACER_ADDRESS]
