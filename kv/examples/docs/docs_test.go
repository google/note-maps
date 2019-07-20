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

package docs

import (
	"fmt"
	"testing"

	"github.com/google/note-maps/kv"
	"github.com/google/note-maps/kv/memory"
)

func TestSchemaSetScanLookup(t *testing.T) {
	store := memory.New()
	schema := Schema{store}
	e, err := store.Alloc()
	if err != nil {
		t.Error(e)
	}
	sample := Document{
		Title:   "Test Title",
		Content: "Ipsum dolor etcetera",
	}
	err = schema.DocumentComponent(0).Set(e, &sample)
	if err != nil {
		t.Error(err)
	}
	ds, err := schema.DocumentComponent(0).Scan([]kv.Entity{e, e})
	if err != nil {
		t.Error(err)
	} else if len(ds) != 2 || ds[0].String() != sample.String() || ds[1].String() != sample.String() {
		t.Error("want", []Document{sample, sample}, "got", ds)
	}
	matches, err := schema.DocumentComponent(0).LookupByTitle("test title")
	if err != nil {
		t.Error(err)
	} else if len(matches) != 1 {
		t.Error("want 1 match, got", len(matches), ":", matches)
	} else {
		ds, err = schema.DocumentComponent(0).Scan(matches)
		if err != nil {
			t.Error(err)
		} else if len(ds) != 1 {
			t.Error("want one documents, got", ds)
		} else if ds[0].Title != "Test Title" {
			t.Errorf("want %v, got %v",
				"Test Title", ds[0].Title)
		}
	}
}

func TestSchemaByTitle(t *testing.T) {
	store := memory.New()
	schema := Schema{store}
	for i := 0; i < 10; i++ {
		for _, name := range []string{"Foo", "Bar", "Quux"} {
			e, err := store.Alloc()
			if err != nil {
				t.Fatal(e)
			}
			err = schema.DocumentComponent(0).Set(e, &Document{
				Title:   fmt.Sprintf("%s #%v", name, i),
				Content: "Ipsum dolor etcetera",
			})
			if err != nil {
				t.Error(err)
			}
		}
	}
	var cursor TitleCursor
	var docs []Document
	already := make(map[kv.Entity]bool)
	for i := 0; ; i++ {
		es, err := schema.DocumentComponent(0).ByTitle(&cursor, 5)
		if err != nil {
			t.Error(err)
			break
		}
		if len(es) == 0 {
			break
		}
		for _, e := range es {
			if already[e] {
				t.Error("duplicate", e)
			}
			already[e] = true
		}
		ds, err := schema.DocumentComponent(0).Scan(es)
		if err != nil {
			t.Error(err)
			break
		}
		docs = append(docs, ds...)
	}
	for i := 1; i < len(docs); i++ {
		if docs[i-1].Title > docs[i].Title {
			t.Errorf("want %#v before %#v, got after",
				docs[i-1].Title, docs[i].Title)
		}
	}
}
