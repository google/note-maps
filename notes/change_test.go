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

func TestSetValue_AffectsID(t *testing.T) {
	v := SetValue{
		ID:       "test0",
		Lexical:  "test1",
		Datatype: "test2",
	}
	if !v.AffectsID("test0") {
		t.Error("SetValue should affect the note whose value is being set")
	}
	if v.AffectsID("test1") {
		t.Error("SetValue should not affect a note whose ID just happens to match the value being set")
	}
	if v.AffectsID("test2") {
		t.Error("SetValue should not affect the note that represents the datatype of the value being set")
	}
}

func TestAddContent_AffectsID(t *testing.T) {
	v := AddContent{
		ID:  "test0",
		Add: "test1",
	}
	if !v.AffectsID("test0") {
		t.Error("AddContent should affect the note whose content is being increased")
	}
	if !v.AffectsID("test1") {
		t.Error("AddContent should affect the note that is being added")
	}
}
