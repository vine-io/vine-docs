---
title: "web服务"
date: 2020-12-29T15:01:46+08:00
draft: false
weight: 15
description: >
  Web 为 vine web 应用提供了一个接口
---

## 概述
**Web** 提供了一个很小的 HTTP Web 服务器库，利用 **Vine** 创建 vine web 服务。它包装了 **Vine**, 为用户提供服务发现，检测信号以及将 web 应用创建为微服务的功能.

## 特性
- 服务发现 - 服务在启动时自动注册在 **Registry** 中。**Web** 包括一个具有预初始化的 http.Client, 它利用服务发现，以便您可以使用 web 服务。
- 健康检测 - **Web** 应用将定期使用服务发现进行检测信号，以提供实时更新。如果服务失败，将在预定义的过期时间后将其从 **Registry** 中删除.
- 自定义处理程序 - 指定您自己的 http 路由器以处理请求。这允许您完全控制要路由到内部处理程序的方式.
- 静态服务 - **Web** 自动检测本地静态 html 目录，如果未指定路由处理程序，则提供文件。对于那些希望将 JS Web 应用程序编写为微服务的用户的快速解决方案.

## 依赖
 Web 使用 **Vine**, 这意味着它需要 **Registry**

## 使用
```go
service := web.NewService(
    web.Name("example.com"),
)

service.HandleFunc("/foo", fooHandler)

if err := service.Init(); err != nil {
    log.Fatal(err)
}

if err := service.Run(); err != nil {
    log.Fatal(err)
}
```
## 设置 handler
```go
import "github.com/gorilla/mux"

r := mux.NewRouter()
r.HandleFunc("/", indexHandler)
r.HandleFunc("/objects/{object}", objectHandler)

service := web.NewService(
    web.Handler(r)
)
```
## 调用服务
web 包括一个具有自定义 http.RoundTripper 并使用服务发现 http.Client
```go
c := service.Client()

rsp, err := c.Get("http://example.com/foo")
```
这将查找 example.com 服务发现以及路由到其中一个可用节点。

## 静态文件                        
**Web** 总是意味着注册 Web 应用， 其中大多数代码将用 JS 编写。 默认情况下， 如果 “/“ 上没有注册任何处理程序，并且我们发现本地的 “html” 目录，则将提供静态文件.

如果要手动设置此路径，请使用 StaticDir 选项。如果指定了相对路径，我们将使用 `os.Getwd()` 和前缀.
```go
service := web.NewService(
    web.Name("example.com"),
    web.StaticDir("/tmp/example.com/html"),
)
```