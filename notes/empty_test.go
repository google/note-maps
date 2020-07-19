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

func TestEmptyNote(t *testing.T) {
	var n Note = EmptyNote("7")
	if id := n.GetID(); id != "7" {
		t.Errorf("got %v, expected %v", id, "7")
	}
	if ns, err := n.GetTypes(); err != nil {
		t.Errorf("got %v, expected nil", err)
	} else if len(ns) != 0 {
		t.Errorf("got %#v, expected empty slice", ns)
	}
	if ns, err := n.GetSupertypes(); err != nil {
		t.Errorf("got %v, expected nil", err)
	} else if len(ns) != 0 {
		t.Errorf("got %#v, expected empty slice", ns)
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
