---
title: "锁和选举"
date: 2021-08-27T09:25:07+08:00
draft: false
weight: 350
description: >
---

## 概述
```go
// Sync is an interface for distributed synchronization
type Sync interface {
	// Init Initialise options
	Init(...Option) error
	// Options Return the options
	Options() Options
	// Leader Elect a leader
	Leader(id string, opts ...LeaderOption) (Leader, error)
	// ListMembers get all election member
	ListMembers(opts ...ListMembersOption) ([]*Member, error)
	// Lock acquires a lock
	Lock(id string, opts ...LockOption) error
	// Unlock releases a lock
	Unlock(id string) error
	// String Sync implementation
	String() string
}
```

## 使用
### 分布式锁
```go
func main() {
    s := etcd.NewSync()
	if err := s.Init(); err != nil {
		log.Fatalln(err)
	}

    // 创建锁
	err := s.Lock("lock1", sync.LockTTL(time.Second * 3))
	if err != nil {
		log.Fatalln(err)
	}

	ch := make(chan struct{}, 1)
	go func() {
		err := s.Lock("lock1", sync.LockTTL(time.Second * 3))
		if err != nil {
			log.Fatalln(err)
		}
		fmt.Println("Locked")
		ch <- struct{}{}
	}()

    // 释放锁
	if err = s.Unlock("lock1"); err != nil {
		log.Fatalln(err)
	}
	fmt.Println("lock1 released")

	<-ch
}
```
### 分布式选举
```go
func main() {
    s := etcd.NewSync()
	if err := s.Init(); err != nil {
		log.Fatalln(err)
	}

	id := uuid.NewString()
    // 新 leader
	role1, err := s.Leader("leader", sync.LeaderNS("default"), sync.LeaderId(id), sync.LeaderTTL(3))
	if err != nil {
		log.Fatalln(err)
	}

    // 查询所有选举成员
    ms, _ := s.ListMembers(sync.MemberNS("default"))
	for _, m := range ms {
		fmt.Println(m)
	}

    // 成员辞职
    if err := role1.Resign(); err != nil {
		log.Fatalln(err)
	}
}
```
## options
初始化
```go
func main() {
	memory.NewSync(
		sync.Prefix("/vine/sync"),    // key 前缀
		sync.Nodes("127.0.0.1:2379"), // 服务端地址
	)
}
```
上锁和释放锁
```go
func main() {
    s.Lock("lock1",
		sync.LockTTL(),   // 锁的 ttl
		sync.LockWait(),  // 超时时间
	)
}
```
选举
```go
func main() {
    s.Leader("leader",
		sync.LeaderNS(), // namespace
		sync.LeaderTTL(), // 
		sync.LeaderId(), // 成员 id
	)
}
```
## 实例
更多的实例代码可参考 [examples](https://github.com/vine-io/examples/tree/main/sync)