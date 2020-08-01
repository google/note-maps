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

package textile

import (
	"context"
	"errors"
	"io/ioutil"
	"os"
	"testing"

	"github.com/google/note-maps/note"
	"github.com/google/note-maps/note/notestest"
	"github.com/textileio/go-threads/core/app"
)

// TestPatchLoad applies some simple operations to a note map and verifies
// their impact in the result.
func TestPatchLoad(t *testing.T) {
	if testing.Short() {
		t.Skip("skipping test that uses IO and network")
	}
	dir, rmdir := testDir(t)
	defer rmdir()
	n := defaultNetwork(t, dir)
	defer func() {
		if err := n.Close(); err != nil {
			t.Fatal(err)
		}
	}()
	nm := open(t, n, WithBaseDirectory(dir))
	defer func() {
		if err := nm.Close(); err != nil {
			t.Fatal(err)
		}
	}()
	var stage note.Stage
	stage.Note("test1").SetValue("Title1", note.EmptyID)
	stage.Note("test2").SetValue("Title2", note.EmptyID)
	if err := nm.IsolatedWrite(func(w note.FindLoadPatcher) error {
		return w.Patch(stage.Ops)
	}); err != nil {
		t.Fatal(err)
	}
	var ns []note.GraphNote
	if err := nm.IsolatedRead(func(r note.FindLoader) error {
		var e error
		ns, e = r.Load([]note.ID{"test1", "test2"})
		return e
	}); err != nil {
		t.Fatal(err)
	}
	if len(ns) != 2 {
		t.Errorf("got %v notes, expected 2", len(ns))
	}
	if len(ns) > 0 {
		notestest.ExpectEqual(t, ns[0], stage.Note("test1"))
	}
	if len(ns) > 1 {
		notestest.ExpectEqual(t, ns[1], stage.Note("test2"))
	}
}

// Make sure we can open the same database more than once.
func TestOpenOpen(t *testing.T) {
	if testing.Short() {
		t.Skip("skipping test that uses IO and network")
	}
	dir, rmdir := testDir(t)
	defer rmdir()
	n := defaultNetwork(t, dir)
	defer n.Close()
	secrets := make(map[string][]byte)
	opts := []Option{
		WithBaseDirectory(dir),
		WithGetSecret(func(k string) ([]byte, error) {
			t.Log("retrieving secret for", k)
			s, ok := secrets[k]
			if !ok {
				return nil, errors.New("no secret")
			}
			return s, nil
		}),
		WithSetSecret(func(k string, s []byte) error {
			t.Log("storing secret for", k)
			secrets[k] = s
			return nil
		}),
	}
	nm0 := open(t, n, opts...)
	id := nm0.GetThreadID()
	if err := nm0.Close(); err != nil {
		t.Fatal(err)
	}
	opts = append(opts, WithThread(id.String()))
	nm1 := open(t, n, opts...)
	if err := nm1.Close(); err != nil {
		t.Fatal(err)
	}
}

func testDir(t *testing.T) (string, func()) {
	dir, err := ioutil.TempDir("", "")
	if err != nil {
		t.Fatal(err)
	}
	t.Log("using dir", dir)
	return dir, func() {
		_ = os.RemoveAll(dir)
	}
}
func defaultNetwork(t *testing.T, d string) app.Net {
	n, err := DefaultNetwork(d)
	if err != nil {
		t.Fatal(err)
	}
	return n
}
func open(t *testing.T, n app.Net, opts ...Option) *Database {
	d, err := Open(context.Background(), n, opts...)
	if err != nil {
		t.Fatal(err)
	}
	return d
}
