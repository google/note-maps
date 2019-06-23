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

package storage

import (
	"io/ioutil"
	"os"
	"reflect"
	"sort"
	"testing"
)

func TestCreateTopicMap(t *testing.T) {
	dir, err := ioutil.TempDir("", "storage-test")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(dir)
	store, err := Open(dir)
	if err != nil {
		t.Fatal(err)
	}
	var stored []*TopicMapInfo
	func() {
		transaction := store.NewTransaction(true)
		stored = append(stored, nil)
		stored[0], err = transaction.CreateTopicMap()
		if err != nil {
			t.Fatal(err)
		}
		stored = append(stored, nil)
		stored[1], err = transaction.CreateTopicMap()
		if err != nil {
			t.Fatal(err)
		}
		if stored[0].TopicMap == stored[1].TopicMap {
			t.Errorf("want distinct values, got %v==%v",
				stored[0].TopicMap, stored[1].TopicMap)
		}
		transaction.Commit()
	}()
	sort.Slice(stored,
		func(a, b int) bool { return stored[a].TopicMap < stored[b].TopicMap })
	var got []*TopicMapInfo
	func() {
		transaction := store.NewTransaction(false)
		defer transaction.Discard()
		cursor := transaction.TopicMaps(TopicMapsQuery{})
		defer cursor.Discard()
		for cursor.Next() {
			info, err := cursor.Info()
			if err != nil {
				t.Error(err)
			} else {
				got = append(got, info)
			}
		}
	}()
	sort.Slice(got,
		func(a, b int) bool { return got[a].TopicMap < got[b].TopicMap })
	if len(stored) != len(got) {
		t.Errorf("want %v topic maps, got %v topic maps", len(stored), len(got))
	} else {
		for i := range stored {
			if !reflect.DeepEqual(stored[i], got[i]) {
				t.Errorf("want %v, got %v", stored[i], got[i])
			}
		}
	}
}
