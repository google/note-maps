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
	"io/ioutil"
	"os"
	"testing"

	"github.com/google/note-maps/notes"
)

func TestSomething(t *testing.T) {
	d, clean := createMemDB(t)
	defer clean()
	defer d.Close()

	var stage notes.Stage
	stage.Note(1).SetValue("Title1", 0)
	stage.Note(2).SetValue("Title2", 0)
	if err := d.Patch(stage.Ops); err != nil {
		t.Error(err)
	}

	ns, err := d.Find(&notes.Query{})
	if err != nil {
		t.Fatal(err)
	}
	if len(ns) != 2 {
		panic("there should be two notes")
	}
}

func createMemDB(t *testing.T) (notes.NoteMap, func()) {
	dir, err := ioutil.TempDir("", "")
	if err != nil {
		t.Fatal(err)
	}
	n, err := DefaultNetwork(dir)
	if err != nil {
		t.Fatal(err)
	}
	d, err := Open(context.Background(), n, WithBaseDirectory(dir))
	if err != nil {
		t.Fatal(err)
	}
	return d, func() {
		if err := n.Close(); err != nil {
			panic(err)
		}
		_ = os.RemoveAll(dir)
	}
}
