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

// Package mobileapi is intended for use with gomobile.
//
// Since gomobile has limited support for Go types, and since it has excellent
// support for byte slices, all non-trivial information is passed through
// mobileapi as encoded protocol buffers.
package mobileapi

import (
	"fmt"
	"log"
	"os"
	"sync"

	"github.com/golang/protobuf/proto"
	"github.com/google/note-maps/kv/badger"
	"github.com/google/note-maps/store/pb"
	"github.com/google/note-maps/store/pbapi"
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
	g, err := gateway()
	if err != nil {
		return nil, err
	}
	switch method {
	case "GetTopicMaps":
		var query pb.GetTopicMapsRequest
		err := proto.Unmarshal(bs, &query)
		if err != nil {
			return nil, err
		}
		response, err := g.GetTopicMaps(&query)
		if err != nil {
			return nil, err
		}
		log.Printf("%s(%s)=>%s", method, query.String(), response.String())
		return proto.Marshal(response)
	default:
		return nil, fmt.Errorf("unrecognized query: %#v", method)
	}
}

func Command(method string, bs []byte) ([]byte, error) {
	g, err := gateway()
	if err != nil {
		return nil, err
	}
	switch method {
	case "CreateTopicMap":
		var cmd pb.CreateTopicMapRequest
		err := proto.Unmarshal(bs, &cmd)
		if err != nil {
			return nil, err
		}
		response, err := g.CreateTopicMap(&cmd)
		if err != nil {
			return nil, err
		}
		log.Printf("%s(%s)=>%s", method, cmd.String(), response.String())
		return proto.Marshal(response)
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

func gateway() (*pbapi.Gateway, error) {
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

	return pbapi.NewGateway(db), nil
}
