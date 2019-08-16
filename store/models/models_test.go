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

package models

import (
	"sort"
	"testing"

	"github.com/google/note-maps/kv"
	"github.com/google/note-maps/kv/memory"
)

func createTopicMap(s *Txn) (*TopicMapInfo, error) {
	entity, err := s.Alloc()
	if err != nil {
		return nil, err
	}
	info := &TopicMapInfo{}
	info.TopicMap = uint64(entity)
	return info, s.SetTopicMapInfo(entity, info)
}

func TestCreateTopicMap(t *testing.T) {
	var (
		err    error
		txn    = New(memory.New())
		es     []kv.Entity
		stored []*TopicMapInfo
	)
	stored = append(stored, nil)
	stored[0], err = createTopicMap(&txn)
	if err != nil {
		t.Fatal(err)
	}
	es = append(es, kv.Entity(stored[0].TopicMap))
	stored = append(stored, nil)
	stored[1], err = createTopicMap(&txn)
	if err != nil {
		t.Fatal(err)
	}
	es = append(es, kv.Entity(stored[1].TopicMap))
	if stored[0].TopicMap == stored[1].TopicMap {
		t.Errorf("want distinct values, got %v==%v",
			stored[0].TopicMap, stored[1].TopicMap)
	}
	if gotEs, err := txn.AllTopicMapInfoEntities(nil, 0); err != nil {
		t.Error(err)
	} else {
		kv.EntitySlice(gotEs).Sort()
		if !kv.EntitySlice(es).Equal(kv.EntitySlice(gotEs)) {
			t.Errorf("want %v, got %v", es, gotEs)
		}
	}
	sort.Slice(stored,
		func(a, b int) bool { return stored[a].TopicMap < stored[b].TopicMap })
	got, err := txn.GetTopicMapInfoSlice(es)
	if err != nil {
		t.Fatal(err)
	}
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
