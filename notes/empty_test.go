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

package notes

import (
	"testing"
)

func TestEmptyID(t *testing.T) {
	var empty ID
	if EmptyID != empty {
		t.Fatal("EmptyID is not the default value")
	}
}

func TestID_Empty(t *testing.T) {
	if !EmptyID.Empty() {
		t.Error("EmptyID is not empty, expected empty")
	}
	if ID("0").Empty() {
		t.Errorf("%#v is empty, expected not empty", ID("0"))
	}
}

func TestEmptyNote(t *testing.T) {
	var n GraphNote = EmptyNote("7")
	if id := n.GetID(); id != "7" {
		t.Errorf("got %v, expected %v", id, "7")
	}
	if s, n, err := n.GetValue(); err != nil {
		t.Errorf("got %v, expected nil", err)
	} else if s != "" || n.GetID() != EmptyID {
		t.Errorf("got %#v, %#v, expected empty string and zero note", s, n)
	}
	if ns, err := n.GetContents(); err != nil {
		t.Errorf("got %v, expected nil", err)
	} else if len(ns) != 0 {
		t.Errorf("got %#v, expected empty slice", ns)
	}
}

func TestEmptyLoader_Load(t *testing.T) {
	ns, err := EmptyLoader.Load([]ID{"this is ok", "this is fine too"})
	if err != nil {
		t.Errorf("got %#v, expected %#v", err, nil)
	} else if len(ns) != 2 {
		t.Fatalf("got %v notes, expected %v", len(ns), 2)
	}
	if ns[0].GetID() != "this is ok" {
		t.Fatalf("got %#v, expected %#v", ns[0].GetID(), "this is ok")
	}
	if ns[1].GetID() != "this is fine too" {
		t.Fatalf("got %#v, expected %#v", ns[0].GetID(), "this is fine too")
	}
}

func TestEmptyLoader_Load_withInvalidID(t *testing.T) {
	_, err := EmptyLoader.Load([]ID{"this is ok", "this is fine too", EmptyID})
	if err != InvalidID {
		t.Errorf("got %#v, expected %#v", err, InvalidID)
	}
}
