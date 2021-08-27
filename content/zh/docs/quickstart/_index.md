---
title: "快速开始"
date: 2020-12-29T10:22:20+08:00
weight: 2
description: >
---

这里提供一个简单的实例，帮助用户快速了解 **Vine** 框架。

## 定义接口

### 新建项目
新建目录保存相关代码:
```bash
$ mkdir $GOPATH/src/greet
```
> 建议项目保存在 $GOPATH 下

### 新建 *.proto 文件
**Vine** 内部使用 `gRPC` 作为服务端，`*.proto` 是 google 公司开源的一种数据交换协议，类似 `json`。关于 `protobuf` 更详细的语法可以参考[protobuf](https://developers.google.com/protocol-buffers/docs/gotutorial)。

这里我们新建 `greet.proto` 文件，内容如下:
```protobuf
// mysite/proto/greet.proto
syntax = "proto3";

package greet;

service Greeter {
  rpc Echo(EchoReq) returns (EchoRsp) {}
}

message EchoReq {
  string name = 1;
}

message EchoRsp {
  string greeting = 1;
}
```
> 更多的关于 **Vine** 的语法规则可以参考 [protoc-gen-vine](/vine/docs/guides/openapi/)

### 生成 API 接口
你需要以下的工具来生成 proto 代码
- [protoc](https://github.com/protocolbuffers/protobuf)
- [protoc-gen-gogo](https://github.com/vine-io/vine/tree/master/cmd/protoc-gen-gogo)
- [protoc-gen-vine](https://github.com/vine-io/vine/tree/master/cmd/protoc-gen-vine)

使用 protoc、protoc-gen-gogo、protoc-gen-vine 来生成 protobuf code
```bash
go get github.com/gogo/protobuf
go get github.com/vine-io/vine/cmd/protoc-gen-gogo
go get github.com/vine-io/vine/cmd/protoc-gen-vine
```
使用命令生成 `greet.pb.go` 和 `greet.vine.go` 文件:
```bash
$ cd $GOPATH/src
$ protoc -I=$GOPATH/src --gogo_out=:. --vine_out=:. mysite/proto/greet.proto
```
执行成功后会生成新的文件:
```bash
mysite
└── proto
    ├── greet.pb.go       # 通过 protoc-gen-gogo 插件生成，包含结构体和 gRPC 的接口
    ├── greet.pb.vine.go  # 通过 protoc-gen-vine 插件生成，包含 Vine 框架接口
    └── greet.proto

```
## 定义服务
### 实现 Vine 服务
有了 proto 文件后，接下来就是编写服务端代码：
```
$ mkdir -p server
$ touch mysite/server/main.go
```
服务端代码:
```go
package main

import (
	"context"
	"log"

	"github.com/vine-io/vine"
	pb "mysite/proto"
)

// greet 需要实现 pb.Greet 的接口
type greet struct {}

func (g *greet) Echo(ctx context.Context, req *pb.EchoReq, rsp *pb.EchoRsp) error {
	rsp.Greeting = "hello: " + req.Name
	return nil
}

func main() {
	// 构建新的服务
	app := vine.NewService(
		vine.Name("greet"),
	)

	// 服务初始化
	app.Init()

	// 注册服务
	if err := pb.RegisterGreeterHandler(app.Server(), &greet{}); err != nil {
		log.Fatalf("register greet hander: %v", err)
	}

	// 服务启动
	if err := app.Run(); err != nil {
		log.Fatalf("start greet server: %v", err)
	}
}
```
这样一个简易的 **Vine** 服务就完成了。

> 更多服务端的内容请参考 [内部服务](/vine/docs/component/server/)
### 启动服务
启动服务并绑定端口:
```bash
$ go run server/main.go
2021-08-27 13:24:18  file=vine/service.go:171 level=info Starting [service] greet
2021-08-27 13:24:18  file=vine/service.go:172 level=info service [version] latest
2021-08-27 13:24:18  file=grpc/grpc.go:920 level=info Server [grpc] Listening on [::]:65235
2021-08-27 13:24:18  file=grpc/grpc.go:761 level=info Registry [mdns] Registering node: greet-d4d5e1a8-1bc0-4387-8fb2-1b5eda59055e
2021-08-27 13:24:18  file=mdns/mdns_registry.go:266 level=info [mdns] registry create new service with ip: 192.168.11.167 for: 192.168.11.167
```
如果用户没有指定 ip 和端口，则默认 ip 为 0.0.0.0，端口随机生成。

> 关于 **Vine** 服务的命令行参数可以参考 [命令行参数](/vine/docs/component/cmd/)

## 客户端
接下来我们编写客户端的代码来请求服务端:
```bash
$ mkdir -p client
$ touch client/main.go
```
客户端代码:
```go
package main

import (
	"context"

	"github.com/vine-io/vine/core/client/grpc"
	log "github.com/vine-io/vine/lib/logger"
	pb "github.com/vine-io/vine/testdata/mysite/proto"
)

func main() {
	// 选择 gRPC 客户端
	cc := grpc.NewClient()
	// 指定服务名称
	client := pb.NewGreeterService("greet", cc)

	// 请求 Greet.Echo 接口
	rsp, err := client.Echo(context.TODO(), &pb.EchoReq{Name: "lack"})
	if err != nil {
		log.Fatal(err)
	}

	log.Infof("greet result: %v", rsp.Greeting)
}
```
执行命令输出如下:
```bash
$ go run client/main.go
2021-08-27 13:24:41  file=client/main.go:20 level=info greet result: hello: lack
```
> 更多关于客户端的内容可以参考 [内部请求](/vine/docs/component/client/)

## API 接口
**Vine** 服务可以同时支持 `gRPC` 和 `Restful` 接口。

### 修改 greet.proto 文件
先修改 greet.proto 文件:
```protobuf
syntax = "proto3";

package greet;

// +gen:openapi
service Greeter {
  // +gen:get=/api/v1/echo
  rpc Echo(EchoReq) returns (EchoRsp) {}
}

message EchoReq {
  string name = 1;
}

message EchoRsp {
  string greeting = 1;
}
```
重新生成 `greet.pb.vine.go` 文件:
```bash
$ protoc -I=$GOPATH/src --vine_out=:.  github.com/vine-io/vine/testdata/mysite/proto/greet.proto
```

### 安装 `vine`:
```bash
$ go get github.com/vine-io/vine/cmd/vine
```

### 启动网关
```bash
$ vine api --handler=rpc --enable-openapi  
2021-08-27 13:38:54  file=openapi/openapi.go:56 level=info Starting OpenAPI at /openapi-ui/
2021-08-27 13:38:54  file=api/api.go:179 level=info Registering API RPC Handler at /
2021-08-27 13:38:54  file=http/http.go:116 level=info HTTP API Listening on [::]:8080
2021-08-27 13:38:54  file=vine/service.go:171 level=info Starting [service] go.vine.api
2021-08-27 13:38:54  file=vine/service.go:172 level=info service [version] latest
2021-08-27 13:38:54  file=grpc/grpc.go:920 level=info Server [grpc] Listening on [::]:50405
2021-08-27 13:38:54  file=grpc/grpc.go:761 level=info Registry [mdns] Registering node: go.vine.api-b405ca1d-ba24-4470-a18e-b1feeb22c5f6
2021-08-27 13:38:54  file=mdns/mdns_registry.go:266 level=info [mdns] registry create new service with ip: 192.168.11.167 for: 192.168.11.167
```
使用以下命令验证:
```bash
$ curl http://127.0.0.1:8080/api/v1/echo\?name\=lack
{"greeting":"hello: lack"}%
```

完成的目录结构如下:
```bash
mysite
├── client
│   └── main.go
├── proto
│   ├── greet.pb.go
│   ├── greet.pb.vine.go
│   └── greet.proto
└── server
    └── main.go
```