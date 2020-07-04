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

	"github.com/google/note-maps/notes/change"
)

type expectation struct {
	vs   string
	cids []uint64
}

func TestDiffNote(t *testing.T) {
	for _, test := range []struct {
		title    string
		fluent   func(dst *Stage)
		input    []change.Operation
		expected map[uint64]expectation
	}{
		{
			"set value and add content",
			func(s *Stage) {
				n1 := s.Note(1)
				n1.SetValue("test value1", 0)
				n3 := n1.AddContent(3)
				n3.SetValue("test value3", 0)
				n4 := s.Note(4)
				n4.SetValue("test value4", 0)
				n1.AddContent(4)
			},
			[]change.Operation{
				change.SetValue{1, "test value1", 0},
				change.AddContent{1, 3},
				change.SetValue{3, "test value3", 0},
				change.SetValue{4, "test value4", 0},
				change.AddContent{1, 4},
			},
			map[uint64]expectation{
				1: {vs: "test value1", cids: []uint64{3, 4}},
				3: {vs: "test value3", cids: []uint64{}},
				4: {vs: "test value4", cids: []uint64{}},
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
					var cids []uint64
					for _, c := range cs {
						cids = append(cids, c.GetId())
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
