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

package store

import (
	"testing"

	"github.com/google/note-maps/kv/kvtest"
	"github.com/google/note-maps/store/models"
	"github.com/google/note-maps/topicmaps/ctm"
)

func TestStore(t *testing.T) {
	db := kvtest.NewDB(t)
	defer db.Close()
	txn := db.NewTxn(true)
	defer txn.Discard()
	store := NewTxn(models.New(txn))
	err := ctm.ParseString(`
		%encoding "UTF-8"
		%version 1.0
		%prefix wiki http://en.wikipedia.org/wiki/

		wiki:Canada - "Canada".
		wiki:Ontario - "Ontario".
	`, store)
	if err != nil {
		t.Log(err) // TODO: Error
	}
	tuples, err := store.QueryString(`. [ . >> characteristics >> atomify == "Ontario ]`)
	if err != nil {
		t.Log(err) // TODO: Error
	}
	t.Log(tuples) // TODO: Check for correctness
}
