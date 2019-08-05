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
	"reflect"
	"testing"

	"github.com/google/note-maps/kv"
	"github.com/google/note-maps/kv/kvtest"
)

func sampleDocuments(t string, n int) []Document {
	ds := make([]Document, n)
	for i := range ds {
		ds[i].Title = fmt.Sprintf("%v %v", t, i)
		ds[i].Content = "Lorem ipsum something"
	}
	return ds
}

func createDocuments(s *Txn, ds []Document) []kv.Entity {
	var (
		err error
		es  = make([]kv.Entity, len(ds))
	)
	for i := range ds {
		es[i], err = s.Alloc()
		if err != nil {
			panic(err)
		}
		if err = s.SetDocument(es[i], &ds[i]); err != nil {
			panic(err)
		}
	}
	return es
}

func verifyDocuments(s *Txn, des []kv.Entity, ds []Document) {
	if len(des) != len(ds) {
		panic(fmt.Sprintf("len(des)=%v, len(ds)=%v", len(des), len(ds)))
	}
	// Check by getting one at a time.
	for i, e := range des {
		want := ds[i]
		got, err := s.GetDocument(e)
		if err != nil {
			panic(err)
		} else if want.Title != got.Title || want.Content != got.Content {
			panic(fmt.Sprintf("%v: want %#v, got %#v", e, want, got))
		}
	}
	// Check by getting all at once.
	slice, err := s.GetDocumentSlice(des)
	if err != nil {
		panic(err)
	} else if len(slice) != len(des) {
		panic(fmt.Sprintf("%v != %v", len(slice), len(des)))
	}
	for i, e := range des {
		want := ds[i]
		got := slice[i]
		if err != nil {
			panic(err)
		} else if want.Title != got.Title || want.Content != got.Content {
			panic(fmt.Sprintf("%v: want %#v, got %#v", e, want, got))
		}
	}
	// Check the index.
	for i, d := range ds {
		matches, err := s.EntitiesMatchingDocumentTitle(d.IndexTitle()[0])
		if err != nil {
			panic(err)
		} else if matches.Search(des[i]) >= len(matches) {
			panic(fmt.Sprintf("did not find %v in documents matching %#v: %#v",
				des[i], d.IndexTitle()[0], matches))
		} else {
			mds, err := s.GetDocumentSlice(matches)
			if err != nil {
				panic(err)
			} else if 1 != len(mds) {
				panic(fmt.Sprintf("want one documents, got %#v", mds))
			} else if d.Title != mds[0].Title {
				panic(fmt.Sprintf("want %v, got %v",
					d.Title, mds[0].Title))
			}
		}
	}
}

func TestCreateRead(t *testing.T) {
	test := func(s_ kv.Txn) {
		s := New(s_)
		samples := sampleDocuments("Test", 5)
		des := createDocuments(&s, samples)
		verifyDocuments(&s, des, samples)
	}
	kvtest.Deflake(t, test)
}

func TestCreateUpdateRead(t *testing.T) {
	test := func(s_ kv.Txn) {
		s := New(s_)
		des := createDocuments(&s, sampleDocuments("Initial", 5))
		revised := sampleDocuments("Revised", 5)
		for i, de := range des {
			s.SetDocument(de, &revised[i])
		}
		verifyDocuments(&s, des, revised)
	}
	kvtest.Deflake(t, test)
}

func TestIterator(t *testing.T) {
	test := func(s_ kv.Txn) {
		s := New(s_)
		createDocuments(&s, sampleDocuments("Foo", 5))
		createDocuments(&s, sampleDocuments("Foo", 5))
		createDocuments(&s, sampleDocuments("Bar", 5))
		for pageSize := 1; pageSize < 11; pageSize++ {
			println("pageSize", pageSize)
			var (
				cursor  kv.IndexCursor
				docs    []Document
				already = make(map[kv.Entity]bool)
			)
			for i := 0; ; i++ {
				println("page", i)
				es, err := s.EntitiesByDocumentTitle(&cursor, pageSize)
				if err != nil {
					panic(err)
					break
				}
				if len(es) == 0 {
					break
				}
				for k := 0; k < len(es); k++ {
					println(es[k])
				}
				for _, e := range es {
					if already[e] {
						t.Fatalf("duplicate %v", e)
					}
					already[e] = true
				}
				ds, err := s.GetDocumentSlice(es)
				if err != nil {
					panic(err)
					break
				}
				docs = append(docs, ds...)
			}
			for i := 1; i < len(docs); i++ {
				if docs[i-1].Title > docs[i].Title {
					t.Fatalf("want %#v before %#v, got after",
						docs[i-1].Title, docs[i].Title)
				}
			}
		}
	}
	kvtest.Deflake(t, test)
}

func TestAllDocumentEntities(t *testing.T) {
	test := func(s_ kv.Txn) {
		s := New(s_)
		want := createDocuments(&s, sampleDocuments("All", 5))
		kv.EntitySlice(want).Sort()
		for pageSize := 1; pageSize < len(want)+1; pageSize++ {
			var (
				start kv.Entity
				got   []kv.Entity
			)
			for {
				buf, err := s.AllDocumentEntities(&start, pageSize)
				if err != nil {
					panic(err)
				}
				got = append(got, buf...)
				if pageSize < len(buf) {
					t.Fatalf("want <= %d entities, got %d", pageSize, len(buf))
				} else if len(buf) < pageSize {
					break
				}
			}
			kv.EntitySlice(got).Sort()
			if !reflect.DeepEqual(want, got) {
				t.Fatalf("want %#v, got %#v", want, got)
			}
		}
	}
	kvtest.Deflake(t, test)
}
