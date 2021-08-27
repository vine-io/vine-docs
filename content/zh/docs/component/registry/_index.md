---
title: "服务注册发现"
date: 2020-12-29T14:57:27+08:00
draft: false
weight: 1
description: >
---

## 概述

```go
// The registry provides an interface for service discovery
// and an abstraction over varying implementations
// {consul, etcd, zookeeper, ...}
type Registry interface {
	Init(...Option) error
	Options() Options
	Register(*regpb.Service, ...RegisterOption) error
	Deregister(*regpb.Service, ...DeregisterOption) error
	GetService(string, ...GetOption) ([]*regpb.Service, error)
	ListServices(...ListOption) ([]*regpb.Service, error)
	Watch(...WatchOption) (regpb.Watcher, error)
	String() string
}
```

## 完整实例
```go
package main

import (
	"fmt"
	"log"
	"time"

	"github.com/google/uuid"
	"github.com/vine-io/vine/service/registry"
	regpb "github.com/vine-io/vine/proto/registry"
)

func main() {
	// create new registry
	r := registry.NewRegistry()

	// initialize registry
	r.Init()

	s := &regpb.Service{
		Name:     "go.vine.srv",
		Version:  "1.0.0",
		Metadata: map[string]string{},
		Endpoints: []*regpb.Endpoint{{
			Request: &regpb.Value{},
		}},
		Nodes: []*regpb.Node{&regpb.Node{
			Id:      uuid.New().String(),
			Address: "127.0.0.1:1111",
		}},
	}

	// registry service
	r.Register(s)

	// watch registry
	w, err := r.Watch(registry.WatchService("go.vine.srv"))
	if err != nil {
		return
	}
	defer w.Stop()
	go func() {
		for {
			// blocking
			r, err := w.Next()
			if err != nil {
				return
			}

			log.Printf("watch [%v] %v", r.Action, r.Service)
		}
	}()

	time.Sleep(time.Second)
	// get service
	service, err := r.GetService("go.vine.srv")
	if err != nil {
		log.Fatal(err)
	}
	fmt.Printf("%+v\n", service)

	// destroy registry
	r.Deregister(s)

	time.Sleep(time.Second)
}
```