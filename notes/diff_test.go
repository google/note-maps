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
	"reflect"
	"testing"
)

type expectation struct {
	vs   string
	cids []ID
}

func TestDiffNote(t *testing.T) {
	for _, test := range []struct {
		title    string
		fluent   func(dst *Stage)
		input    []Operation
		expected map[ID]expectation
	}{
		{
			"set value and add content",
			func(s *Stage) {
				n1 := s.Note("1")
				n1.SetValue("test value1", EmptyID)
				n3 := n1.AddContent("3")
				n3.SetValue("test value3", EmptyID)
				n4 := s.Note("4")
				n4.SetValue("test value4", EmptyID)
				n1.AddContent("4")
			},
			[]Operation{
				SetValue{"1", "test value1", EmptyID},
				AddContent{"1", "3"},
				SetValue{"3", "test value3", EmptyID},
				SetValue{"4", "test value4", EmptyID},
				AddContent{"1", "4"},
			},
			map[ID]expectation{
				"1": {vs: "test value1", cids: []ID{"3", "4"}},
				"3": {vs: "test value3", cids: []ID{}},
				"4": {vs: "test value4", cids: []ID{}},
			},
		},
	} {
		var stage Stage
		test.fluent(&stage)
		if !reflect.DeepEqual(stage.Ops, test.input) {
			t.Error("got", stage.Ops, "expected", test.input)
		}
		stage.Ops = nil
		for _, op := range test.input {
			stage.Add(op)
		}
		for id, expected := range test.expected {
			t.Run(test.title, func(t *testing.T) {
				actual := stage.Note(id)
				if vs, _, err := actual.GetValue(); err != nil {
					t.Error(err)
				} else if vs != expected.vs {
					t.Errorf("got %#v, expected %#v", vs, expected.vs)
				}
				if cs, err := actual.GetContents(); err != nil {
					t.Error(err)
				} else {
					var cids []ID
					for _, c := range cs {
						cids = append(cids, c.GetID())
					}
					if !(len(cids) == 0 && len(expected.cids) == 0) &&
						!reflect.DeepEqual(cids, expected.cids) {
						t.Errorf("got %#v, expected %#v", cids, expected.cids)
					}
				}
			})
		}
	}
}
