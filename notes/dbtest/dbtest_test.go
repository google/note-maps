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

package dbtest

import (
	"bytes"
	"errors"
	"fmt"
	"regexp"
	"testing"

	"github.com/google/note-maps/notes"
)

func TestRandomID(t *testing.T) {
	done := make(map[notes.ID]bool)
	for i := 0; i < 1000000; i++ {
		id := RandomID()
		if dupe := done[id]; dupe {
			t.Errorf("duplicate id %v", id)
		}
		done[id] = true
	}
}

func TestBreakingLoader_Load(t *testing.T) {
	var l = BreakingLoader{Loader: notes.EmptyLoader, Err: errors.New("testing")}
	if _, err := l.Load(nil); err != nil {
		t.Error("expected no error for empty requet, got", err)
	}
	if l.Count != 0 {
		t.Error("expected count", 0, "got", l.Count)
	}
	for i := 1; i < 4; i++ {
		ids := make([]notes.ID, i)
		for k := range ids {
			ids[k] = RandomID()
		}
		l.ErrAtCount = l.Count
		if ns, err := l.Load(ids); err != nil {
			if err == nil {
				t.Error("expected count", 1, "got", l.Count)
			} else if err.Error() != l.Err.Error() {
				t.Error("expected", l.Err, "got", err)
			}
			if len(ns) != 0 {
				t.Error("expected zero notes in error response, got", len(ns))
			}
		}
		l.ErrAtCount = l.Count + 1
		if ns, err := l.Load(ids); err != nil {
			if err != nil {
				t.Error("expected", nil, "got", err)
			}
			if len(ns) != len(ids) {
				t.Error("expected", len(ids), "notes in error response, got", len(ns))
			}
		}
	}
}

func TestBrokenNote(t *testing.T) {
	id := RandomID()
	expectErr := errors.New("testing")
	var n notes.Note = BrokenNote{id, expectErr}
	if n.GetID() != id {
		t.Error("got", n.GetID(), "expected", id)
	}
	expectBroken(t, n, expectErr)
}

func expectBroken(t *testing.T, n notes.Note, expectErr error) {
	vs, vt, err := n.GetValue()
	if err == nil || err.Error() != expectErr.Error() {
		t.Errorf("broken note GetValue would return %v, got %v",
			expectErr, err)
	}
	if vs != "" || vt != nil {
		t.Errorf("broken note should have empty value, found %#v, %#v", vs, vt)
	}
	cs, err := n.GetContents()
	if err == nil || err.Error() != expectErr.Error() {
		t.Errorf("expected broken note.GetValue would return %#v, got %#v",
			expectErr, err)
	}
	if len(cs) != 0 {
		t.Errorf("broken note should have empty contents, found %#v", cs)
	}
}

func TestBrokenNoteLoader(t *testing.T) {
	var l notes.Loader = &BrokenNoteLoader{errors.New("testing broken note loader")}
	// BrokenNoteLoader is actually a well-behaved loader.
	TestLoader(t, l)
}

type fakeT struct {
	*testing.T
	b *bytes.Buffer
}

func (t *fakeT) Error(args ...interface{}) { fmt.Fprintln(t.b, args...) }

type loaderFunc func([]notes.ID) ([]notes.Note, error)

func (l loaderFunc) Load(ids []notes.ID) ([]notes.Note, error) { return l(ids) }

func TestTestLoader_acceptsEmptyLoader(t *testing.T) {
	TestLoader(t, notes.EmptyLoader)
}

func TestTestLoader(t *testing.T) {
	good := notes.EmptyLoader
	for _, test := range []struct {
		Title  string
		L      notes.Loader
		Expect string
	}{
		{"accepts empty loader", notes.EmptyLoader, ""},
		{
			"verifies empty request gets no error",
			loaderFunc(func(ids []notes.ID) ([]notes.Note, error) {
				if len(ids) == 0 {
					return nil, errors.New("bad error for empty request")
				}
				return good.Load(ids)
			}),
			"bad error for empty request\n",
		},
		{
			"verifies empty request gets no notes",
			loaderFunc(func(ids []notes.ID) ([]notes.Note, error) {
				if len(ids) == 0 {
					return []notes.Note{notes.EmptyNote("0")}, nil
				}
				return good.Load(ids)
			}),
			"expected zero notes, got 1\n",
		},
		{
			"verifies request for one note gets no error",
			loaderFunc(func(ids []notes.ID) ([]notes.Note, error) {
				if len(ids) == 1 {
					return nil, errors.New("testing error")
				}
				return good.Load(ids)
			}),
			"testing error\n",
		},
		{
			"verifies request for one note gets one note",
			loaderFunc(func(ids []notes.ID) ([]notes.Note, error) {
				if len(ids) == 1 {
					return nil, nil
				}
				return good.Load(ids)
			}),
			"expected one note, got 0 and no error\n",
		},
		{
			"verifies request for one note gets right note",
			loaderFunc(func(ids []notes.ID) ([]notes.Note, error) {
				if len(ids) == 1 {
					return []notes.Note{notes.EmptyNote("nope")}, nil
				}
				return good.Load(ids)
			}),
			"expected .* got nope\n",
		},
		{
			"verifies request for multiple notes gets no error",
			loaderFunc(func(ids []notes.ID) ([]notes.Note, error) {
				ns, err := good.Load(ids)
				if len(ids) > 1 && err == nil {
					err = errors.New("error for multiple notes")
				}
				return ns, err
			}),
			"error for multiple notes\n",
		},
		{
			"verifies request for multiple notes gets right number of notes",
			loaderFunc(func(ids []notes.ID) ([]notes.Note, error) {
				ns, err := good.Load(ids)
				if len(ids) > 1 && err == nil {
					ns = ns[:1]
				}
				return ns, err
			}),
			"expected 3 notes, got 1\n",
		},
		{
			"verifies request for multiple notes gets notes in the right order",
			loaderFunc(func(ids []notes.ID) ([]notes.Note, error) {
				ns, err := good.Load(ids)
				if len(ns) > 2 {
					ns[1], ns[2] = ns[2], ns[1]
				}
				return ns, err
			}),
			"(. expected ID .* got ID .*\n){2}",
		}, {
			"verifies request for invalid IDs gets InvalidID",
			loaderFunc(func(ids []notes.ID) ([]notes.Note, error) {
				for _, id := range ids {
					if id.Empty() {
						return nil, errors.New("some other error")
					}
				}
				return good.Load(ids)
			}),
			"(with bad ID at .* expected invalid .*\n)+",
		},
	} {
		t.Run(test.Title, func(t *testing.T) {
			ft := &fakeT{t, bytes.NewBuffer(nil)}
			TestLoader(ft, test.L)
			actual := ft.b.String()
			match, err := regexp.MatchString("^"+test.Expect+"$", actual)
			if err != nil {
				panic(err)
			} else if !match {
				t.Errorf("got %#v, expected %#v", actual, test.Expect)
			}
		})
	}
}
