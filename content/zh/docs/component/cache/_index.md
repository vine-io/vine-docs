---
title: "数据缓存"
date: 2020-12-29T15:01:40+08:00
draft: false
weight: 90
description: >
  
---

```go
// Cache is a data cache interface
type Cache interface {
	// Init initialises the cache. It must perform any required setup on the backing storage implementation and check that it is ready for use, returning any errors.
	Init(...Option) error
	// Options allows you to view the current options.
	Options() Options
	// Get takes a single key name and optional GetOptions. It returns matching []*Record or an error.
	Get(key string, opts ...GetOption) ([]*Record, error)
	// Put writes a record to the cache, and returns an error if the record was not written.
	Put(r *Record, opts ...PutOption) error
	// Del removes the record with the corresponding key from the cache.
	Del(key string, opts ...DelOption) error
	// List returns any keys that match, or an empty list with no error if none matched.
	List(opts ...ListOption) ([]string, error)
	// Close the cache
	Close() error
	// String returns the name of the implementation.
	String() string
}

// Record is an item cached or retrieved from a Cache
type Record struct {
	// The key to cache the record
	Key string `json:"key"`
	// The value within the record
	Value []byte `json:"value"`
	// Any associated metadata for indexing
	Metadata map[string]interface{} `json:"metadata"`
	// Time to expire a record: TODO: change to timestamp
	Expiry time.Duration `json:"expiry,omitempty"`
}
```