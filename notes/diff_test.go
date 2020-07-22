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
	"errors"
	"reflect"
	"testing"
)

type breakingLoader struct {
	Loader
	count      int
	errAtCount int
	err        error
}

func (l *breakingLoader) Load(ids []ID) ([]Note, error) {
	l.count++
	if l.errAtCount == l.count-1 && l.err != nil {
		return nil, l.err
	}
	return l.Loader.Load(ids)
}

type brokenNote struct {
	ID
	err error
}

func (n brokenNote) GetID() ID                       { return n.ID }
func (n brokenNote) GetValue() (string, Note, error) { return "", nil, n.err }
func (n brokenNote) GetContents() ([]Note, error)    { return nil, n.err }

type brokenNoteLoader struct{ err error }

func (l *brokenNoteLoader) Load(ids []ID) ([]Note, error) {
	ns := make([]Note, len(ids))
	for i, id := range ids {
		ns[i] = brokenNote{ID: id, err: l.err}
	}
	return ns, nil
}

type expectation struct {
	vs   string
	cids []ID
}

func TestStage_Note(t *testing.T) {
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
		t.Run(test.title, func(t *testing.T) {
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
				t.Run(string(id), func(t *testing.T) {
					l0 := breakingLoader{Loader: EmptyLoader}
					stage.Base = &l0
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
					if testing.Short() {
						t.Skip("skipping exhaustive error-handling test in short mode.")
					}
					for b := 0; b < l0.count; b++ {
						var (
							expected error = InvalidID
							l1             = breakingLoader{
								Loader:     EmptyLoader,
								errAtCount: b,
								err:        expected,
							}
							actual = func() error {
								stage.Base = &l1
								n := stage.Note(id)
								// Repeat the same Get* calls on n with l1 as were called earlier
								// with l0.
								if _, _, err := n.GetValue(); err != nil {
									return err
								}
								if _, err := n.GetContents(); err != nil {
									return err
								}
								return nil
							}()
						)
						if actual != expected {
							t.Errorf("expected %v at load #%v, got %v", expected, b, actual)
						}
					}
					expected := errors.New("broken note")
					stage.Base = &brokenNoteLoader{err: expected}
					n := stage.Note(id)
					if _, _, err := n.GetValue(); err != expected {
						t.Errorf("expected %v, got %v", expected, err)
					}
					if _, err := n.GetContents(); err != expected {
						t.Errorf("expected %v, got %v", expected, err)
					}
				})
			}
		})
	}
}

func TestStage_Base_notNil(t *testing.T) {
	var s Stage
	if s.GetBase() == nil {
		t.Error("expected Stage{}.Base() to be non-nil")
	}
}

func TestNote_SetValue_panicWithInvalidID(t *testing.T) {
	var s Stage
	n := s.Note("1")
	n.ID = "2"
	n.SetValue("value3", "4")
	func() {
		defer func() {
			if err := recover(); err == nil {
				t.Error("expected panic for mutation of note with invalid ID")
			}
		}()
		n.ID = ""
		n.SetValue("value3", "4")
	}()
}

func TestNote_AddContent_panicWithInvalidID(t *testing.T) {
	var s Stage
	n := s.Note("1")
	n.ID = "3"
	n.AddContent("2")
	func() {
		defer func() {
			if err := recover(); err == nil {
				t.Error("expected panic for mutation of note with invalid ID")
			}
		}()
		n.ID = ""
		n.AddContent("4")
	}()
}
