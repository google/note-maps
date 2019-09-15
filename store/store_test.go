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

	"github.com/golang/protobuf/proto"
	"github.com/google/note-maps/kv/kvtest"
	"github.com/google/note-maps/store/models"
	"github.com/google/note-maps/store/pb"
	"github.com/google/note-maps/topicmaps/ctm"
)

func TestStore(t *testing.T) {
	for itest, test := range []struct {
		CTM   string
		Query string
		Want  string
		Mask  pb.Mask
	}{
		{
			CTM: `
				%prefix wiki http://en.wikipedia.org/wiki/
				wiki:Canada - "Canada".
				wiki:Ontario - "Ontario".`,
			Query: `<http://en.wikipedia.org/wiki/Canada> >> characteristics`,
			Mask:  pb.Mask_ValueMask,
			Want:  `tuples: { items: { value: "Canada" } }`,
		},
	} {
		db := kvtest.NewDB(t)
		defer db.Close()
		txn := db.NewTxn(true)
		defer txn.Discard()
		s := NewTxn(models.New(txn))
		if err := ctm.ParseString(test.CTM, s); err != nil {
			t.Logf("%v: error: %v", itest, err) // TODO: Error
		}
		var want pb.TupleSequence
		if err := proto.UnmarshalText(test.Want, &want); err != nil {
			t.Fatalf("%v: can't unmarshal wanted response: %s", itest, err)
		}
		if got, err := s.QueryString(test.Query); err != nil {
			t.Logf("%v: error: %v", itest, err) // TODO: Error
		} else if !proto.Equal(got, &want) {
			t.Logf("%v: got %s, want %s", itest, got.String(), want.String()) // TODO: Error
		}
	}
}
