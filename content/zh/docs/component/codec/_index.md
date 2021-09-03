---
title: "序列化"
date: 2021-08-27T09:17:09+08:00
draft: false
weight: 10
description: >
---

## 概述
我们抽象出 `Codec` 和 `Marshaler` 接口来统一管理数据的序列化和反序列功能。`Codec` 被 `Server` 和 `Client` 使用作为数据解析工具。`Marshaler` 为用户提供数据转化工具。

目前 `Marshaler` 接口支持以下格式：
- yaml
- json
- bytes
- proto
```go
type Codec interface {
	Reader
	Writer
	Close() error
	String() string
}

type Reader interface {
	ReadHeader(*Message, MessageType) error
	ReadBody(interface{}) error
}

type Writer interface {
	Write(*Message, interface{}) error
}

type Marshaler interface {
	Marshal(interface{}) ([]byte, error)
	Unmarshal([]byte, interface{}) error
	String() string
}
```
## 具体实现
只要用户提供了 `Marshal`, `Unmarshal` 和 `String` 方法即可实现 `Marshaler` 接口，以下提供一个完整的 `json` 版本代码:
```go

var jsonbMarshaler = &mjsonpb.Marshaler{}

// create buffer pool with 16 instances each preallocated with 256 bytes
var bufferPool = bpool.NewSizedBufferPool(16, 256)

type Marshaler struct{}

func (j Marshaler) Marshal(v interface{}) ([]byte, error) {
	if pb, ok := v.(proto.Message); ok {
		buf := bufferPool.Get()
		defer bufferPool.Put(buf)
		if err := jsonbMarshaler.Marshal(buf, pb); err != nil {
			return nil, err
		}
		return buf.Bytes(), nil
	}
	return json.Marshal(v)
}

func (j Marshaler) Unmarshal(d []byte, v interface{}) error {
	if pb, ok := v.(proto.Message); ok {
		return mjsonpb.Unmarshal(bytes.NewReader(d), pb)
	}
	return json.Unmarshal(d, v)
}

func (j Marshaler) String() string {
	return "json"
}
```

## 使用
### 注册 
```go
func main() {
	encoding.RegisterMarshaler("json", &Marshaler{})
}
```
### 获取
```go
func main() {
	m, ok := encoding.GetMarshaler("json")
}
```
### 序列化和反序列化
```go
package main

import (
	"fmt"

	"github.com/vine-io/vine/core/codec/encoding"
)

type Person struct {
	Name string `json:"name"`
	Age  int32  `json:"age"`
}

func main() {
	m, _ := encoding.GetMarshaler("json")
	p := &Person{
		Name: "Vine",
		Age:  20,
	}

	data, _ := m.Marshal(p)
	fmt.Println(string(data))

	p1 := new(Person)
	m.Unmarshal(data, &p1)
	fmt.Println(p1.Name)
}
```