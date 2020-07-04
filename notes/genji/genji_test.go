// Copyright 2020 Google LLC
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

// Package genji implements notes/pbdb interfaces to store Note Maps in a Genji
// database.
package genji

import (
	"reflect"
	"testing"

	"github.com/google/note-maps/notes"
	"github.com/google/note-maps/notes/pbdb"
	"github.com/google/note-maps/notes/pbdb/pb"

	"github.com/golang/protobuf/proto"
	//"github.com/genjidb/genji"
	//"github.com/genjidb/genji/document"
)

func memoryDb(t *testing.T) pbdb.Db {
	db, err := Open(":memory:")
	if err != nil {
		t.Fatal(err)
	}
	return db
}

func Test_NewNoteMapIsEmpty(t *testing.T) {
	db := memoryDb(t)
	defer db.Close()
	txn := db.NewReaderTransaction()
	defer txn.Discard()
	ids, err := txn.Find(&notes.Query{})
	if err != nil {
		t.Error(err)
	} else if len(ids) != 0 {
		t.Errorf("expected new empty notemap, found ids: %v", ids)
	}
}

func Test_StoreFindLoad(t *testing.T) {
	db := memoryDb(t)
	defer db.Close()
	txn := db.NewReadWriterTransaction()
	defer txn.Discard()
	input := &pb.Note{
		Id:       1,
		Value:    &pb.Note_Value{Lexical: "test value"},
		Contents: []uint64{2, 3},
	}
	err := txn.Store([]*pb.Note{input})
	if err != nil {
		t.Fatal(err)
	}
	if ids, err := txn.Find(&notes.Query{}); err != nil {
		t.Error(err)
	} else if !reflect.DeepEqual(ids, []uint64{1}) {
		t.Errorf("got %#v, expected 1", ids)
	}
	if ns, err := txn.Load(1); err != nil {
		t.Error(err)
	} else if len(ns) != 1 {
		t.Errorf("got %v notes, expected %v", len(ns), 1)
	} else if !proto.Equal(ns[0], input) {
		t.Errorf("got %v, expected %v", ns[0], input)
	}
}

func Test_StoreDeleteFindLoad(t *testing.T) {
}
