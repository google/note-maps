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
	"sort"
	"testing"

	"github.com/google/note-maps/kv"
	"github.com/google/note-maps/kv/memory"
)

func TestCreateTopicMap(t *testing.T) {
	var (
		err    error
		store  = Store{Store: memory.New()}
		es     []kv.Entity
		stored []*TopicMapInfo
	)
	stored = append(stored, nil)
	stored[0], err = store.CreateTopicMap()
	if err != nil {
		t.Fatal(err)
	}
	es = append(es, kv.Entity(stored[0].TopicMap))
	stored = append(stored, nil)
	stored[1], err = store.CreateTopicMap()
	if err != nil {
		t.Fatal(err)
	}
	es = append(es, kv.Entity(stored[1].TopicMap))
	if stored[0].TopicMap == stored[1].TopicMap {
		t.Errorf("want distinct values, got %v==%v",
			stored[0].TopicMap, stored[1].TopicMap)
	}
	sort.Slice(stored,
		func(a, b int) bool { return stored[a].TopicMap < stored[b].TopicMap })
	got, err := store.GetTopicMapInfoSlice(es)
	if len(stored) != len(got) {
		t.Errorf("want %v topic maps, got %v topic maps", len(stored), len(got))
	} else {
		for i := range stored {
			if stored[i].String() != got[i].String() {
				t.Errorf("want %v, got %v", stored[i], got[i])
			}
		}
	}
}
