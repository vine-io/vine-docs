---
title: "Function"
weight: 2
date: 2020-12-29T10:32:20+08:00
description: >
  这是一份关于如何编写 Function 服务的指南。Function 是指只执行一次的服务。
---

```go
// Function 一次性执行服务
type Function interface {
	// 内置服务接口
	Service
	// 接口服务
	Done() error
	// 处理 rpc 请求
	Handle(v interface{}) error
	// 订阅者
	Subscribe(topic string, v interface{}) error
}
```

## 1.初始化

使用 `service.NewFunction` 创建 Function
```go
import "github.com/lack-io/vine"

function = vine.NewFunction()
```

创建时使用选项
```go
function = vine.NewService(
    vine.Name("greeter"),
    vine.Version("latest"),
)
```

支持的选项，请看[这里](https://pkg.go.dev/github.com/lack-io/vine/service#Option)

**Vine** 同时支持使用`service.Flags` 来提供命令行参数:

```go

import (
	"fmt"

	"github.com/lack-io/cli"
	"github.com/lack-io/vine"
)

	function := vine.NewFunction(
		vine.Flags(&cli.StringFlag{
			Name:  "environment",
			Usage: "The environment",
		}),
	)
```
使用 `service.Init` 解析参数，并且使用 `service.Action` 选项来访问参数：
```go
	function.Init(
		vine.Action(func(c *cli.Context) error {
			env := c.String("environment")
			if len(env) > 0 {
				fmt.Println("Environment set to", env)
			}

			return nil
		}),
	)
```
`service.Init` 支持的选择看[这里](https://pkg.go.dev/github.com/lack-io/vine/service/config/cmd#pkg-variables)

## 2.定义 API
使用 protobuf 文件定义服务的 API 接口。它可以能便利的提供严谨的 API 接口，同时为服务端和客户端提供具体的接口。
greeter.proto
```protobuf
syntax = "proto3";

service Greeter {
	rpc Hello(Request) returns (Response) {}
}

message Request {
	string name = 1;
}

message Response {
	string greeting = 2;
}
```
这里我们定义一个 Greeter 服务，提供 Hello 方法。Request 和 Response 是 Hello 方法的入参和返回值。

## 3.生成 API 接口
使用 protoc、protoc-gen-gogo、protoc-gen-vine 来生成 protobuf code
```bash
go get github.com/gogo/protobuf
go get github.com/lack-io/vine/cmd/protoc-gen-gogo
go get github.com/lack-io/vine/cmd/protoc-gen-vine
```
```bash
protoc -I=$GOPATH/src -I=$GOPATH/src/github.com/gogo/protobuf/protobuf --gogo_out=:. --vine_out=. greeter.proto
```
它会生成以下代码:

```go
type Request struct {
	Name string `protobuf:"bytes,1,opt,name=name" json:"name,omitempty"`
}

type Response struct {
	Greeting string `protobuf:"bytes,2,opt,name=greeting" json:"greeting,omitempty"`
}

// Client API for Greeter service

type GreeterClient interface {
	Hello(ctx context.Context, in *Request, opts ...client.CallOption) (*Response, error)
}

type greeterClient struct {
	c           client.Client
	serviceName string
}

func NewGreeterClient(serviceName string, c client.Client) GreeterClient {
	if c == nil {
		c = client.NewClient()
	}
	if len(serviceName) == 0 {
		serviceName = "greeter"
	}
	return &greeterClient{
		c:           c,
		serviceName: serviceName,
	}
}

func (c *greeterClient) Hello(ctx context.Context, in *Request, opts ...client.CallOption) (*Response, error) {
	req := c.c.NewRequest(c.serviceName, "Greeter.Hello", in)
	out := new(Response)
	err := c.c.Call(ctx, req, out, opts...)
	if err != nil {
		return nil, err
	}
	return out, nil
}

// Server API for Greeter service

type GreeterHandler interface {
	Hello(context.Context, *Request, *Response) error
}

func RegisterGreeterHandler(s server.Server, hdlr GreeterHandler) {
	s.Handle(s.NewHandler(&Greeter{hdlr}))
}
```

## 4.实现 handler

handler.go
```go
import proto "github.com/vine/examples/service/proto"

type Greeter struct{}

func (g *Greeter) Hello(ctx context.Context, req *pb.Request, rsp *pb.Response) error {
	rsp.Greeting = "Hello " + req.Name
	return nil
}
```
这个 handler 将被注册为服务，就像 http.Handler.

```go
function = vine.NewFunction(
    vine.Name("greeter"),
)

pb.RegisterGreeterHandler(function.Server, new(Greeter))
```

## 5.启动 Function
服务通过调用 `function.Run` 来启动。它会绑定到配置参数提供的地址上并且监听请求。
服务启动时会通过 registry 组件注册服务，在接收到 kill 信号时注销服务。

```go
if err := function.Run(); err != nil {
    log.Fatal(err)
}
```

## 6.完整的服务端代码
```go
package main

import (
        "log"
        "context"

        "github.com/lack-io/vine"
        pb "github.com/lack-io/examples/service/proto"
)

type Greeter struct{}

func (g *Greeter) Hello(ctx context.Context, req *pb.Request, rsp *pb.Response) error {
        rsp.Greeting = "Hello " + req.Name
        return nil
}

func main() {
        function := vine.NewFunction(
                vine.Name("greeter"),
        )

        function.Init()

        pb.RegisterGreeterHandler(function.Server(), new(Greeter))

        if err := function.Run(); err != nil {
                log.Fatal(err)
        }
}
```

## 客户端
查询上面的 Function，可以使用以下的代码
```go
// 创建 greeter 服务的客户端
greeter := pb.NewGreeterService("greeter", function.Client())

// 请求 Greeter 的 Hello 方法
rsp, err := greeter.Hello(context.TODO(), &pb.Request{
	Name: "John",
})
if err != nil {
	fmt.Println(err)
	return
}

fmt.Println(rsp.Greeting)
```