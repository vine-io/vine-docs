---
title: "服务网关"
date: 2020-12-29T14:58:34+08:00
draft: false
weight: 8
description: >
---

## 概述
**API** 是一个可插拔的 API 接口，由 **Registry** 驱动，可帮助构建强大的公共 API 网关.

**API** 库提供 api 网关路由功能。微服务体系结构将应用程序逻辑分离到单独的服务中. api 网关提供单个入口点，以将这些服务合并到统一 api 中。 **API** 使用在 **Registry** 元数据中定义的路由来生成路由规则并服务 http 请求.

## 启动 api 服务
```bash
# 提供 http 服务和 swagger 
vine api --handler=rpc --enable-openapi
```
## 创建网关
```bash
vine new gateway api
```
启动
```bash
go run cmd/api/main.go --api-address=127.0.0.1:8080
```
> 一个服务同时提供 gRPC 和 http 接口可以参考 [api](https://github.com/vine-io/examples/tree/main/api)
## 测试
```bash
curl -X POST "http://127.0.0.1:8080/helloworld/v1/helloworld/Call" -H  "accept: application/json" -H  "Content-Type: application/json" -d "{\"name\":\"hello\"}"
> {"msg":"reply: hello"}
```

## 同时支持 grpc 和 http
vine 支持在同一个端口下同时提供 gRPC 和 http 服务。

```go
import (
	"net/http/pprof"

	"github.com/gin-gonic/gin"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"github.com/vine-io/vine"
	grpcServer "github.com/vine-io/vine/core/server/grpc"
	ahandler "github.com/vine-io/vine/lib/api/handler"
	"github.com/vine-io/vine/lib/api/handler/openapi"
	arpc "github.com/vine-io/vine/lib/api/handler/rpc"
	"github.com/vine-io/vine/lib/api/resolver"
	"github.com/vine-io/vine/lib/api/resolver/grpc"
	"github.com/vine-io/vine/lib/api/router"
	regRouter "github.com/vine-io/vine/lib/api/router/registry"
	log "github.com/vine-io/vine/lib/logger"
	"github.com/vine-io/vine/testdata/proto/rpc"
	"github.com/vine-io/vine/util/namespace"
)

type EchoRpc struct{}

func (e EchoRpc) Echo(ctx *vine.Context, request *rpc.EchoRequest, response *rpc.EchoResponse) error {
	response.Msg = request.Msg
	return nil
}

var _ rpc.EchoRpcHandler = (*EchoRpc)(nil)

func main() {

	app := gin.New()
	app.Use(gin.Recovery())

	app.GET("/metrics", gin.WrapH(promhttp.Handler()))

	DefaultPrefix := "/debug/pprof"
	prefixRouter := app.Group(DefaultPrefix)
	{
		prefixRouter.GET("/", gin.WrapF(pprof.Index))
		prefixRouter.GET("/cmdline", gin.WrapF(pprof.Cmdline))
		prefixRouter.GET("/profile", gin.WrapF(pprof.Profile))
		prefixRouter.POST("/symbol", gin.WrapF(pprof.Symbol))
		prefixRouter.GET("/symbol", gin.WrapF(pprof.Symbol))
		prefixRouter.GET("/trace", gin.WrapF(pprof.Trace))
		prefixRouter.GET("/allocs", gin.WrapH(pprof.Handler("allocs")))
		prefixRouter.GET("/block", gin.WrapH(pprof.Handler("block")))
		prefixRouter.GET("/goroutine", gin.WrapH(pprof.Handler("goroutine")))
		prefixRouter.GET("/heap", gin.WrapH(pprof.Handler("heap")))
		prefixRouter.GET("/mutex", gin.WrapH(pprof.Handler("mutex")))
		prefixRouter.GET("/threadcreate", gin.WrapH(pprof.Handler("threadcreate")))
	}

	s := vine.NewService(vine.Address(":8090"))

	s.Init()

	openapi.RegisterOpenAPI(s.Options().Client, s.Options().Registry, app)

	Type, Namespace := "api", "go.vine"
	HandlerType := "rpc"

	// create the namespace resolver
	nsResolver := namespace.NewResolver(Type, Namespace)
	// resolver options
	rops := []resolver.Option{
		resolver.WithNamespace(nsResolver.ResolveWithType),
		resolver.WithHandler(HandlerType),
	}

	log.Infof("Registering API RPC Handler at %s", "/")
	rr := grpc.NewResolver(rops...)
	rt := regRouter.NewRouter(
		router.WithHandler(arpc.Handler),
		router.WithResolver(rr),
		router.WithRegistry(s.Options().Registry),
	)

	rp := arpc.NewHandler(
		ahandler.WithNamespace(Namespace),
		ahandler.WithRouter(rt),
		ahandler.WithClient(s.Client()),
	)
	app.Use(rp.Handle)

	s.Server().Init(grpcServer.HttpHandler(app))

	rpc.RegisterEchoRpcHandler(s.Server(), new(EchoRpc))
	openapi.RegisterOpenAPIHandler(s.Server())

	s.Run()
}
```