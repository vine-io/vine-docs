---
title: "定时任务"
date: 2021-09-01T10:20:54+08:00
draft: true
weight: 500
description: >
---
**Vine** 服务内部携带定时任务调度器，用户可以注册 `Job`，服务启动时，调度器同时启动。
## 新建
我们来尝试创建一个任务:
```go
package main

import (
	"fmt"
	"log"
	"time"

	"github.com/vine-io/gscheduler"
	"github.com/vine-io/vine"
)

func main() {
	job := gscheduler.JobBuilder().
		Name("testjob").          // 任务名称，唯一值
		Duration(time.Second).    // 任务触发间隔时间
		Fn(func() {               // 任务业务主体
			fmt.Println("done!")
		}).
		Out()                     // 返回 *Job

    // 添加定时任务
	if err := vine.AddJob(job); err != nil {
		log.Fatalln(err)
	}

	s := vine.NewService()
	s.Init()
	s.Run()
}
```
## 构建过程
我们提供一组方法来简化定时任务的创建过程。

创建定时任务:
```go
func main() {
    job := gscheduler.JobBuilder().
		Name("testjob").
		Duration(time.Second).
		Fn(func() {
			fmt.Println("done!")
		}).
		Out()
}
```
创建 crontab 定时任务:
```go
import (
    ...
    "github.com/vine-io/gscheduler"
	"github.com/vine-io/gscheduler/cron"
)

func main() {
    // crontab 表达式格式: 秒 分 时 日 月 周
    c, err := cron.Parse("*/3 * * * * *")
	if err != nil {
		log.Fatalf("invalid crontab expr: %v", err)
	}

    // c = cron.Every(time.Second)

	job := gscheduler.JobBuilder().
		Name("testjob").
		Spec(c).
		Fn(func() {
			fmt.Println("done!")
		}).
		Out()
}
```
创建一次性任务:
```go
func main() {
    job := gscheduler.JobBuilder().
		Name("testjob").
		Delay(time.Now().Add(time.Second * 2)).
		Fn(func() {
			fmt.Println("done!")
		}).
		Out()
}
```
额外的功能:
```go
func main() {
    job := gscheduler.JobBuilder().
		Name("testjob").
		Duration(time.Second).
		Silent().  // 任务静默
		Times(3).  // 指定任务执行次数
		Fn(func() {
			fmt.Println("done!")
		}).
		Out()
}
```
## 其他
内部定时任务调度器的其他功能:
```go
func main() {
    // 根据 id 获取任务
    j, _ := vine.GetJob(job.ID())
    // 更新任务
	vine.UpdateJob(j)
    // 删除任务
	vine.RemoveJob(j)
}
```