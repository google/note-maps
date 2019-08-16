// Copyright 2019 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Package mobileapi is intended for use with `gomobile`.
package mobileapi

import (
	"fmt"
	"log"
	"os"
	"sync"

	"github.com/golang/protobuf/proto"
	"github.com/google/note-maps/kv"
	"github.com/google/note-maps/kv/badger"
	"github.com/google/note-maps/store"
	"github.com/google/note-maps/store/pb"
	"github.com/google/note-maps/store/query"
)

func SetPath(p string) {
	m.Lock()
	defer m.Unlock()
	if path == "" {
		path = p
	}
}

func Close() {
	m.Lock()
	defer m.Unlock()
	if err := db.Close(); err != nil {
		log.Println("could not close database:", err)
	}
	db = nil
}

func Query(method string, bs []byte) ([]byte, error) {
	txn, err := newQueryTxn()
	if err != nil {
		return nil, err
	}
	defer txn.Discard()
	switch method {
	case "GetTopicMaps":
		var request pb.GetTopicMapsRequest
		if err := proto.Unmarshal(bs, &request); err != nil {
			return nil, err
		}

		q := store.Query(txn)
		es, err := q.AllTopicMapInfoEntities(nil, 0)
		if err != nil {
			return nil, err
		}
		log.Println("found", len(es), "topic maps")

		var response pb.GetTopicMapsResponse
		for _, e := range es {
			q.Partition = e
			topic, err := q.LoadTopic(e, query.Names|query.Occurrences)
			if err != nil {
				return nil, err
			}

			tm := &pb.TopicMap{
				Id:    uint64(e),
				Topic: topic,
			}
			response.TopicMaps = append(response.TopicMaps, tm)
		}

		return proto.Marshal(&response)
	default:
		return nil, fmt.Errorf("unrecognized query: %#v", method)
	}
}

func Command(method string, bs []byte) ([]byte, error) {
	txn, err := newCommandTxn()
	if err != nil {
		return nil, err
	}
	defer txn.Discard()
	switch method {
	case "CreateTopicMap":
		c := store.Command(txn)
		e, err := c.CreateTopicMap()
		if err != nil {
			return nil, err
		}

		q := store.Query(txn)
		q.Partition = e
		topic, err := q.LoadTopic(e, query.Names|query.Occurrences)
		if err != nil {
			return nil, err
		}

		if err = txn.Commit(); err != nil {
			return nil, err
		}

		return proto.Marshal(&pb.CreateTopicMapResponse{
			TopicMap: &pb.TopicMap{
				Id:    uint64(e),
				Topic: topic,
			},
		})
	default:
		return nil, fmt.Errorf("unrecognized command: %#v", method)
	}
}

const (
	permissions = 0700
)

var (
	db   *badger.DB
	m    sync.Mutex
	path string
)

func getDB() (*badger.DB, error) {
	m.Lock()
	defer m.Unlock()

	if db == nil {
		if path == "" {
			return nil, fmt.Errorf("incomplete initialization: path is empty")
		}
		err := os.MkdirAll(path, permissions)
		if err != nil {
			return nil, err
		}

		options := badger.DefaultOptions(path)

		// Default options leads to a failure on Android, "Map log file.
		// Path=.../000000.vlog. Error=cannot allocate memory"
		//
		// A fix suggested in https://github.com/ipfs/ipfs-cluster/issues/771 is to
		// decrease the ValueLogFileSize.
		options = options.WithValueLogFileSize(1 << 24)

		db, err = badger.Open(options)
		if err != nil {
			return nil, err
		}
	}

	return db, nil
}

func newQueryTxn() (kv.TxnDiscarder, error) {
	db, err := getDB()
	if err != nil {
		return nil, err
	}
	return db.NewTxn(false), nil
}

func newCommandTxn() (kv.TxnCommitDiscarder, error) {
	db, err := getDB()
	if err != nil {
		return nil, err
	}
	return db.NewTxn(true), nil
}
