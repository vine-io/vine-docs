---
title: "错误"
date: 2020-12-29T14:55:02+08:00
draft: false
weight: 2
description: >
  Vine 为错误提供抽象和类型。通过提供一组核心错误和定义详细错误类型，我们可以始终如一地了解运行时出现的错误。
---

## 概述
我们定义以下错误类型
```go
type Error struct {
	Id       string     `json:"id,omitempty"`
	Code     int32      `json:"code,omitempty"`
	Detail   string     `json:"detail,omitempty"`
	Status   string     `json:"status,omitempty"`
    Position string     `json:"position,omitempty"`
    Stacks   []*Stack   `json:"stacks,omitempty"`
}
```
在系统中，要求用户从处理程序返回错误或从客户端接收错误的任何位置，都应认为是 **Vine** 错误，或者应该生成错误。默认情况下，我们返回 `errors.InternalServerError`，如果出现错误错误则返回 `errors.Timeout`。

## 使用
让我们假设程序中发生错误，然后，你应该确定返回哪种错误，并执行以下操作。
假设提供的数据无效：
```go
return errors.badRequest("com.example.srv.service", "invalid field")
```

如果发生内部错误
```go
if err != nil {
    return errors.InternalServerError("com.example.srv.service", "failed to read db: %v", err.Error())
}
```
如果你从客户端收到一些错误，可以按照以下方式处理:
```go
cc := pb.NewGreeterService("go.vine.srv.greeter", service.Client())
rsp, err := pb.Clinet(ctx, req)
if err != nil {
    // parse out the error 
    e := errors.Parse(err.Error())

    // inspect the value
    if e.Code == 401 {
        // unauthorized
    }
}
```

## 错误列表
```go
func BadGateway(id, format string, a ...interface{}) *errors.Error
func BadRequest(id, format string, a ...interface{}) *errors.Error
func Conflict(id, format string, a ...interface{}) *errors.Error
func Forbidden(id, format string, a ...interface{}) *errors.Error
func GatewayTimeout(id, format string, a ...interface{}) *errors.Error
func InternalServerError(id, format string, a ...interface{}) *errors.Error
func MethodNotAllowed(id, format string, a ...interface{}) *errors.Error
func NotFound(id, format string, a ...interface{}) *errors.Error
func NotImplemented(id, format string, a ...interface{}) *errors.Error
func ServiceUnavailable(id, format string, a ...interface{}) *errors.Error
func Timeout(id, format string, a ...interface{}) *errors.Error
func Unauthorized(id, format string, a ...interface{}) *errors.Error
```

## 自定义错误
除了内置的错误类型之外，**Vine** 支持自定义错误类型
```go
// 自定义错误，并记录错误位置
customErr := errors.New("go.vine.srv.example", "custom error", 510, true)
```

## 其他

判断错误类型是否相同
```go
b := errors.Equal(err1, err2)
```

链式调用
```go
e := errors.New("go.vine.srv.example", "name must be set", 404).
        Caller(). // 记录错误位置 
		Stack(10001, "stack context") // 追加上下文信息 
```

