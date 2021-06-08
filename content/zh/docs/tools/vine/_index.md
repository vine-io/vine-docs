---
title: "Vine"
date: 2021-06-04T17:08:23+08:00
draft: false
weight: 1
description: >
  在 **vine** 框架下我们提供一套命令行管理工具，用来管理项目和实现与 **vine** 服务的交互
---

## 安装 vine 工具
```bash
go get github.com/lack-io/vine/cmd/vine
```
验证安装结果
```bash
$ vine --help
NAME:
   vine - A vine service runtime
        _
 _   __(_)___  ___
| | / / / __ \/ _ \
| |/ / / / / /  __/
|___/_/_/ /_/\___/

USAGE:
   vine [global options] command [command options] [arguments...]

VERSION:
   ...

COMMANDS:
   api      Run the api gateway
   new      Create vine resource template
   init     Initialize a vine project
   build    Build vine project or resource
   run      Start a vine project
   help, h  Shows a list of commands or help for one command

GLOBAL OPTIONS:
   --help, -h     show help (default: false)
   --version, -v  print the version (default: false)
```

vine 命令行工具支持多个子命令，包含以下功能:
 - 启动网关
 - 项目管理 (创建，编译，运行)

## vine 项目管理
`new`, `init`, `build`, `run` 可能帮助开发人员很好的管理 vine 实现的项目。接下来我们使用该工具一步步实现单服务的管理

### 初始化项目
新建目录 `$GOPATH/src/example` (建议将项目目录保存在 GOPATH 下。)
```bash
$ mkdir $GOAPTH/src/example
$ cd $GOPATH/src/example
```
在项目目录下执行初始化操作:
```bash
$ vine init 
Creating resource  in $GOPATH/src/example

.
├── vine.toml
├── README.md
├── .gitignore
└── go.mod
```
初始化话生成以上文件，`vine.toml` 中包含项目相关的信息，包含该文件的目录就会被识别为 `vine` 项目。

### 新建服务
执行以下命令创建一个服务:
```bash
$ vine new service 
Creating resource example in $GOPATH/src/example

.
├── cmd
│   └── main.go
├── pkg
│   ├── runtime
│   │   └── doc.go
│   ├── plugin.go
│   ├── app.go
│   ├── server
│   │   └── example.go
│   ├── service
│   │   ├── example.go
│   │   └── wire.go
│   └── dao
│       └── example.go
├── deploy
│   ├── Dockerfile
│   ├── example.ini
│   └── example.service
├── proto
│   └── service
│       └── example
│           └── v1
│               └── example.proto
└── vine.toml


download protoc zip packages (protoc-$VERSION-$PLATFORM.zip) and install:

visit https://github.com/protocolbuffers/protobuf/releases

download protobuf for vine:

cd example

install dependencies:
   go get github.com/google/wire/cmd/wire
	go get github.com/gogo/protobuf
	go get github.com/lack-io/vine/cmd/protoc-gen-gogo
	go get github.com/lack-io/vine/cmd/protoc-gen-vine
	go get github.com/lack-io/vine/cmd/protoc-gen-validator
	go get github.com/lack-io/vine/cmd/protoc-gen-deepcopy
	go get github.com/lack-io/vine/cmd/protoc-gen-dao

cd example
	vine build example
```
### 安装依赖包
根据提示，安装依赖
```bash
$ go get github.com/google/wire/cmd/wire
$ go get github.com/gogo/protobuf
$ go get github.com/lack-io/vine/cmd/protoc-gen-gogo
$ go get github.com/lack-io/vine/cmd/protoc-gen-vine
$ go get github.com/lack-io/vine/cmd/protoc-gen-validator
$ go get github.com/lack-io/vine/cmd/protoc-gen-deepcopy
$ go get github.com/lack-io/vine/cmd/protoc-gen-dao
```
### 编译项目
生成 `*.pb.go` 代码:
```bash
$ vine build proto --type=service  --group=example example
change directory $GOPATH/src:
protoc -I=$GOPATH/src --gogo_out=:. --vine_out=:. --validator_out=:. example/proto/service/example/v1/example.proto
```
编译成二进制文件:
```bash
$ go mod vendor
go: finding module for package github.com/google/wire
go: found github.com/google/wire in github.com/google/wire v0.5.0
$ vine build service example
vine build service example
go build -a -installsuffix cgo -ldflags "-s -w" cmd/main.go
speed: 17.907776483s
```
### 运行服务
```bash
$ ./main
2021-06-05 08:47:29  file=vine/service.go:199 level=info Starting [service] go.vine.service.example
2021-06-05 08:47:29  file=vine/service.go:200 level=info service [version] latest
2021-06-05 08:47:29  file=grpc/grpc.go:878 level=info Server [grpc] Listening on [::]:51530
2021-06-05 08:47:29  file=grpc/grpc.go:719 level=info Registry [mdns] Registering node: go.vine.service.example-81ec2a02-c402-42d7-88c8-3de75a68a49b
2021-06-05 08:47:29  file=mdns/mdns_registry.go:266 level=info [mdns] registry create new service with ip: 192.168.11.167 for: 192.168.11.167
```
## vine 项目结构
vine 项目采用合理的结构，使代码结构变得清晰易理解。项目分成两种类型，`cluster` 分布式和 `single` 单服务。两种类型的目录结构上有一些区别
```bash
# 单服务项目
.
├── cmd  # 服务入口目录, single类型时目录下只有 main.go 文件，cluster 下包含多个服务同名的目录，内部有 main.go 文件
│   └── main.go
├── pkg  # pkg 每个服务核心代码存放下该目录下，single类型时，目录下直接存放服务代码，cluster类型时，目录还有一层服务同名的子目录。
│   ├── runtime  # 各服务公用的工具包和 client 等
│   │   └── doc.go
│   ├── plugin.go # vine 服务的插件信息
│   ├── app.go    # 服务入口，初始化的一些代码
│   ├── server    # 提供 rpc 服务，只进行一些数据的验证，具体工具调用 service
│   │   └── example.go
│   ├── service   # 服务业务逻辑代码
│   │   ├── example.go
│   │   └── wire.go # 使用 github.com/google/wire 实现 DI
│   └── dao       # 数据库交互代码，有 protoc 工具自动生成
│       └── example.go
├── deploy    # 项目代码部署时需要的文件，single 和 cluster 结构上不同
│   ├── Dockerfile # 服务 Dockerfile
│   ├── example.ini # 服务的启动参数配置文件
│   └── example.service # CentOS 上的服务脚本
├── proto    # 存放 *.proto 文件及其生成的 *.go 代码，分成 apis 和 service 类型
│   └── service # 提供 gRPC 服务，引用 proto/apis 下的 message  
│       └── example # 和服务同名的目录
│           └── v1  # 服务接口版本，默认为 v1
│               └── example.proto
└── vine.toml # vine 项目的描述文件，有该文件则被认定为 vine 项目。
```
`vine.toml` 文件内容说明
```bash
[package]   
kind = "single" # 项目类型
namespace = "go.vine" # 项目的命令空间

[pkg]  # kind = "single" 该配置存在，描述服务信息。
name = "example" # 服务命令
alias = "go.vine.service.example" # 别名
type = "service"  # 服务类型,提供 gRPC 接口，service, web, gateway
version = "latest" # 服务版本
main = "cmd/main.go" # main 函数路径
dir = "example" # 项目目录路径，$GOPATH/src 下
output = "" # 服务编译时，输入路径 go build -o $output main.go
flags = [   # 服务编译时的额外参数，支持多个格式，"KEY=value", "-key", "key=${shell command}"  
	"-a", "-installsuffix", "cgo", "-ldflags \"-s -w\"",
]

[[mod]]  # kind = "cluster" 该配置存在，描述服务信息。每个 mod 表示一个服务
name = "apiserver"
alias = "com.howlink.service.apiserver"
type = "service"
version = "latest"
main = "cmd/apiserver/main.go"
dir = "dr/apiserver"
output = "_output/apiserver"
flags = [
	"GOOS=linux", "GOARCH=amd64", "-a", "-installsuffix", "cgo", "-ldflags \"-s -w\"",
]

[[proto]] # .proto 文件描述信息
name = "example" # 文件名
pb = "example/proto/service/example/v1/example.proto" # 路径
type = "service" # 类型，service 和 api
group = "example" # 组，同个 group 下不同有同名的 proto 文件
version = "v1" # 版本，默认为 v1
plugins = ["gogo", "vine", "validator"] # 生成 .go 代码时启用的 protoc 插件
```

## vine 命令解析
`vine` 工具支持以下子命令:
- api      启动网关服务
- new      创建服务或者proto文件
- init     初始化项目，将一个目录转化为项目目录
- build    编译服务、生成 .go 文件
- run      运行服务

### init 子命令
`vine init` 支持以下参数
```bash
$ vine init --help    
NAME:
   vine init - Initialize a vine project

USAGE:
   vine init [command options] [arguments...]

OPTIONS:
   --namespace string  Namespace for the project e.g com.example (default: "go.vine") # 指定项目的命令空间
   --cluster           create cluster package. (default: false) # 确认项目类型，默认为单服务
   --help, -h          show help (default: false)
```
vine 项目支持 cluster (多服务分布式)、single (单服务，默认) 两种类型。

### new 子命令
```bash
$ NAME:
   vine new - Create vine resource template

USAGE:
   vine new command [command options] [arguments...]

COMMANDS:
   service  Create a service template  # 创建一个 gRPC 服务
   gateway  Create a gateway template  # 创建一个网关服务
   web      Create a web template      # 创建一个 web 服务
   proto    Create a proto file        # 创建 proto 文件
   help, h  Shows a list of commands or help for one command

OPTIONS:
   --help, -h     show help (default: false)
   --version, -v  print the version (default: false)
   
```
### build 子命令
```bash
$ vine build --help
NAME:
   vine build - Build vine project or resource

USAGE:
   vine build command [command options] [arguments...]

COMMANDS:
   proto    Generate protobuf file  # 生成 proto 对应的go代码
   service  Build vine project      # 编译服务
   help, h  Shows a list of commands or help for one command

OPTIONS:
   --help, -h     show help (default: false)
   --version, -v  print the version (default: false)

```
### run 子命令
```bash
$ vine run --help          
NAME:
   vine run - Start a vine project

USAGE:
   vine run [command options] [arguments...]

OPTIONS:
   --auto-restart   # 是否在监听到文件变动时自动重启，默认为 true
   --watch strings  # 监听指定目录的文件内容变化
   --help, -h       show help (default: false)

```

// TODO