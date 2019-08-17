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

package pbapi

import (
	"io/ioutil"
	"os"
	"testing"

	"github.com/google/note-maps/kv/badger"
	"github.com/google/note-maps/store/pb"
)

func TestCreateGetTopicMap(t *testing.T) {
	dir, err := ioutil.TempDir("", "kvtest-badger")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(dir)
	var topicMap uint64
	func() {
		db, err := badger.Open(badger.DefaultOptions(dir))
		if err != nil {
			t.Fatal(err)
		}
		defer db.Close()
		g := NewGateway(db)
		createResponse, err := g.CreateTopicMap(&pb.CreateTopicMapRequest{})
		if err != nil {
			t.Fatal(err)
		} else if createResponse.TopicMap == nil {
			t.Fatal("want non-nil TopicMap, got nil")
		} else if createResponse.TopicMap.Id == 0 {
			t.Error("want non-zero TopicMap.Id, got zero")
		}
		topicMap = createResponse.TopicMap.Id
		if createResponse.TopicMap.Topic == nil {
			t.Fatal("want non-nil TopicMap.Topic, got nil")
		} else if createResponse.TopicMap.Topic.Id == 0 {
			t.Fatal("want non-zero TopicMap.Topic.Id, got nil")
		} else if createResponse.TopicMap.Topic.Id != createResponse.TopicMap.Id {
			t.Fatalf("want TopicMap.Id==TopicMap.Topic.Id, got %v!=%v",
				createResponse.TopicMap.Id,
				createResponse.TopicMap.Topic.Id)
		}
		getResponse, err := g.GetTopicMaps(&pb.GetTopicMapsRequest{})
		db.Dump(os.Stderr)
		if err != nil {
			t.Fatal(err)
		} else if len(getResponse.TopicMaps) != 1 {
			t.Errorf("want list of one topic map, got %v", getResponse.TopicMaps)
		}
		if topicMap != getResponse.TopicMaps[0].Id {
			t.Errorf("want %v, got %v",
				topicMap, getResponse.TopicMaps[0].Id)
		}
		if topicMap != getResponse.TopicMaps[0].Topic.Id {
			t.Errorf("want %v, got %v",
				topicMap, getResponse.TopicMaps[0].Topic.Id)
		}
		db.Sync()
	}()
	func() {
		db, err := badger.Open(badger.DefaultOptions(dir))
		if err != nil {
			t.Fatal(err)
		}
		defer db.Close()
		g := NewGateway(db)
		getResponse, err := g.GetTopicMaps(&pb.GetTopicMapsRequest{})
		db.Dump(os.Stderr)
		if err != nil {
			t.Fatal(err)
		} else if len(getResponse.TopicMaps) != 1 {
			t.Errorf("want list of one topic map, got %v", getResponse.TopicMaps)
		}
		if topicMap != getResponse.TopicMaps[0].Id {
			t.Errorf("want %v, got %v",
				topicMap, getResponse.TopicMaps[0].Id)
		}
		if topicMap != getResponse.TopicMaps[0].Topic.Id {
			t.Errorf("want %v, got %v",
				topicMap, getResponse.TopicMaps[0].Topic.Id)
		}
	}()
}
