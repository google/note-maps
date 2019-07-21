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

package memory

import (
	"fmt"
	"reflect"
	"sync"
	"testing"

	"github.com/google/note-maps/kv"
)

func TestAlloc(t *testing.T) {
	store := New()
	done := make(map[kv.Entity]bool)
	var wg sync.WaitGroup
	ch := make(chan kv.Entity, 100)
	for i := 0; i < 20; i++ {
		wg.Add(1)
		go func() {
			for k := 0; k < 1000; k++ {
				e, err := store.Alloc()
				if err != nil {
					t.Fatal(err)
				}
				ch <- e
			}
			wg.Done()
		}()
	}
	go func() {
		wg.Wait()
		close(ch)
	}()
	for e := range ch {
		if done[e] {
			t.Fatal("duplicated", e)
		}
		done[e] = true
	}
}

func TestSetGet(t *testing.T) {
	tests := []struct {
		Key   kv.Entity
		Value kv.String
	}{
		{
			Key:   1,
			Value: "",
		},
		{
			Key:   42,
			Value: "what",
		},
	}
	store := New()
	for _, test := range tests {
		if err := store.Set(test.Key.Encode(), test.Value.Encode()); err != nil {
			t.Error(err)
		}
	}
	for _, test := range tests {
		var got kv.String
		if err := store.Get(test.Key.Encode(), got.Decode); err != nil {
			t.Error(err)
		} else if test.Value != got {
			t.Error("want", test.Value, "got", got)
		}
	}
}

func TestIterator(t *testing.T) {
	store := New()
	for _, salutation := range []string{"hello", "good morning", "good afternoon"} {
		for i, neighbor := range []string{"world", "friend", "desk"} {
			s := fmt.Sprintf("%s%v", salutation, i)
			if err := store.Set([]byte(s), []byte(neighbor)); err != nil {
				t.Fatal(err)
			}
		}
	}
	got := make(map[string]kv.String)
	iter := store.PrefixIterator([]byte("good afternoon"))
	defer iter.Discard()
	for iter.Seek(nil); iter.Valid(); iter.Next() {
		sk := string(iter.Key())
		var v kv.String
		if err := iter.Value(v.Decode); err != nil {
			t.Error(err)
		}
		if _, done := got[sk]; done {
			t.Error("got key twice", sk)
		}
		got[sk] = v
	}
	if len(got) != 3 {
		t.Error("want 3 elements, got", len(got))
	}
	want := map[string]kv.String{
		"0": "world",
		"1": "friend",
		"2": "desk",
	}
	if !reflect.DeepEqual(want, got) {
		t.Error("want", want, "got", got)
	}
}
