---
title: "序列化"
date: 2021-08-27T09:17:09+08:00
draft: false
weight: 10
description: >
---

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
```

