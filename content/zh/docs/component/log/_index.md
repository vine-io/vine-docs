---
title: "日志接口"
date: 2021-08-27T09:22:32+08:00
draft: false
weight: 250
description: >
---

## 概述
`Logger` 是 **Vine** 的日志模块，我们抽象一个一组通用的接口，用户可以根据自己的需要来构建自己的实现:
```go
type Logger interface {
	// Init initialises options
	Init(options ...Option) error
	// Options the Logger options
	Options() Options
	// Fields set fields to always be logged
	Fields(fields map[string]interface{}) Logger
	// Log writes a log entry
	Log(level Level, v ...interface{})
	// Logf writes a formatted log entry
	Logf(level Level, format string, v ...interface{})
	// String returns the name of logger
	String() string
}
```

## 使用
这里介绍 `Logger` 的简单使用方式，我们在内部已经有自带的实现:
```go
func main() {
    // 新 Logger
    l := logger.NewLogger(WithLevel(TraceLevel))
	h1 := logger.NewHelper(l).WithFields(map[string]interface{}{"key1": "val1"})
	h1.Trace("trace_msg1")
	h1.Log(WarnLevel, "warn_msg1")

	h2 := logger.NewHelper(l).WithFields(map[string]interface{}{"key2": "val2"})
	h2.Trace("trace_msg2")
	h2.Warn("warn_msg2")

    // 设置 Fields
	l.Fields(map[string]interface{}{"key3": "val4"}).Log(InfoLevel, "test_msg")

    // 使用默认的 logger
	logger.Fields(map[string]interface{}{"key1": "val1"})
	logger.Info("info")
}
``` 
查看输出:
```bash
2021-09-05 16:29:32 file=logger/logger_test.go:10 key1=val1 level=trace trace_msg1
2021-09-05 16:29:32 file=logger/logger_test.go:11 key1=val1 level=warn warn_msg1
2021-09-05 16:29:32 file=logger/logger_test.go:14 key2=val2 level=trace trace_msg2
2021-09-05 16:29:32 file=logger/logger_test.go:15 key2=val2 level=warn warn_msg2
2021-09-05 16:29:32 file=logger/logger_test.go:17 key3=val4 level=info test_msg
2021-09-05 16:29:32 file=logger/logger_test.go:20 key1=val1 level=info info
```
默认的实现支持以下几种级别日志：
- TRACE: 日志追踪
- DEBUG: 调试日志
- INFO: 普通提示
- WARN: 警告，有错误但不影响正常运行
- ERROR: 错误，功能无法正常执行
- FATAL: 严重错误，触发会导致程序崩溃