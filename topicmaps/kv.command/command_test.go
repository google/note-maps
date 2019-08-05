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

package logic

import (
	"io/ioutil"
	"os"
	"testing"

	"github.com/google/note-maps/kv"
	"github.com/google/note-maps/kv/badger"
	"github.com/google/note-maps/topicmaps/kv.models"
)

func TestCreateTopicMap(t *testing.T) {
	dir, err := ioutil.TempDir("", "TestNew-*")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(dir)
	db, err := badger.Open(badger.DefaultOptions(dir))
	if err != nil {
		t.Fatal(err)
	}
	txn := db.NewTransaction(true)
	defer txn.Discard()
	s := Txn{models.New(db.NewTxn(txn))}
	stored, err := s.CreateTopicMap()
	if err != nil {
		t.Error(err)
	} else if stored == 0 {
		t.Error("want not-zero, got zero")
	}
	txn.Commit()
	txn = db.NewTransaction(false)
	defer txn.Discard()
	s = Txn{models.New(db.NewTxn(txn))}
	gots, err := s.GetTopicMapInfoSlice([]kv.Entity{kv.Entity(stored)})
	if err != nil {
		t.Error(err)
	} else if len(gots) != 1 {
		t.Error("want 1 result, got", len(gots))
	} else if kv.Entity(gots[0].TopicMap) != stored {
		t.Errorf("want %v, got %v", stored, &gots[0].TopicMap)
	}
}
