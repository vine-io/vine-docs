---
title: "项目结构"
date: 2021-08-26T16:11:18+08:00
draft: false
weight: 3
description: >
---

**Vine** 提供命令行工具创建项目，其中包括了开发过程中需要的工具链和部署内容。符合 DDD 设计规范。

## 单服务
单服务目录结构使用以下命令创建:
```bash
mkdir $PATH/src/foo
vine init
vine new service foo
```
生成目录结构:
```bash
├── Makefile
├── README.md
├── api  // ------ 维护 grpc 接口，和 domain 层中领域模型
│   └── service
│       └── foo
│           └── v1
│               ├── foo.pb.go
│               ├── foo.pb.validator.go
│               ├── foo.pb.vine.go
│               └── foo.proto
├── cmd         // ------ 项目入口
│   └── main.go
├── deploy    // ------- 部署相关工具
│   ├── Dockerfile
│   ├── foo.ini
│   └── foo.service
├── go.mod
├── go.sum
├── pkg  // 服务内部代码
│   ├── app  // ------- DDD 的 application 层，
│   │   └── foo.go
│   ├── app.go  // -------- 构造和组合各层代码，提供给 cmd/main.go
│   ├── biz  // ---------- DDD 的 domain 层，维护业务代码
│   │   └── foo.go
│   ├── infra  // --------- DDD 的 infrastructure 层，底层通用代码
│   │   ├── cache  // -------- 缓存相关
│   │   │   └── cache.go
│   │   └── repo  // ------- 数据库 repository，数据交互
│   │       └── repo.go
│   ├── interfaces   // ---------- DDD 的 interfaces 层，提供对外的 gRPC 接口 
│   │   └── foo.go
│   └── runtime
│       ├── doc.go  // 维护服务版本信息
│       └── inject  // ------ 维护依赖注入代码
│           └── inject.go
└── vine.toml   // -------- vine 项目的描述文件
```

## 多服务
当一个项目中有多个微服务时，我们推荐代码在一个目录中维护，使用以下命令创建
```bash
mkdir -p $GOPATH/src/cluster
cd $GOPATH/src/cluster

vine init --cluster
vine new service helloworld
```
生成以下目录结构:
```bash
├── Makefile
├── README.md
├── api
│   └── service
│       └── helloworld
│           └── v1
│               └── helloworld.proto
├── cmd
│   └── helloworld
│       └── main.go
├── deploy
│   ├── config
│   │   └── helloworld.ini
│   ├── docker
│   │   └── helloworld
│   │       └── Dockerfile
│   └── systemd
│       └── helloworld.service
├── go.mod
├── pkg   
│   ├── helloworld // -------- 多服务是，pkg 每个目录代码一个服务
│   │   ├── app
│   │   │   └── helloworld.go
│   │   ├── app.go
│   │   ├── biz
│   │   │   └── helloworld.go
│   │   ├── infra
│   │   │   ├── cache
│   │   │   │   └── cache.go
│   │   │   └── repo
│   │   │       └── repo.go
│   │   └── interfaces
│   │       └── helloworld.go
│   └── runtime  // ------ 多个服务间的通用代码
│       ├── doc.go
│       └── inject
│           └── inject.go
└── vine.toml
```

## vine.toml
`vine.toml` 是 **Vine** 项目的描述文件，当一个目录底下存在该文件时，会被识别为 **Vine** 项目。

`vine.toml` 存在两种格式，single 和 cluster。

### single 
```bash
[package]               # [package] 描述项目的公共信息 
kind = "single"         # 项目类型 single 和 cluster
namespace = "go.vine"   # 统一的命名空间

[pkg]      # single 项目详细信息
name = "foo"  # 项目名称
alias = "go.vine.service.foo" # 服务名称
type = "service"    # 服务类型 service, gateway
version = "latest"  # 服务版本
main = "cmd/main.go" # 服务入口文件
dir = "github.com/lack-io/foo"  # 服务核心代码目录
output = ""  # 编译成二进制文件的存放目录
flags = [
	"-a", "-installsuffix", "cgo", "-ldflags \"-s -w\"",  # 编译参数, 支持shell命令作为值 "name=$(echo hello)"
]

[[proto]]    # *.proto 文件信息
name = "foo" # proto 文件名称
pb = "github.com/lack-io/foo/api/service/foo/v1/foo.proto" # proto 文件路径
type = "service" # proto 类型 service 和 api； service 表示 gRPC 服务，api 表示领域模型
group = "foo" # proto 分组
version = "v1" # proto 版本
plugins = ["gogo", "vine", "validator"] # 执行 protoc 命令时携带的插件，可选 gogo、vine、validator、deepcopy、dao
```

### cluster
```bash
[package]
kind = "cluster"
namespace = "go.vine"

[[mod]]  # 每个 mod 表示一个服务
name = "helloworld"
alias = "go.vine.service.helloworld"
type = "service"
version = "latest"
main = "cmd/helloworld/main.go"
dir = "github.com/lack-io/foo/helloworld"
output = ""
flags = [
	"-a", "-installsuffix", "cgo", "-ldflags \"-s -w\"", 
]

[[proto]]
name = "helloworld"
pb = "github.com/lack-io/foo/api/service/helloworld/v1/helloworld.proto"
type = "service"
group = "helloworld"
version = "v1"
plugins = ["gogo", "vine", "validator"]
```