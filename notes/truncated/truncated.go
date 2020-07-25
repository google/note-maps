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

package truncated

import (
	"sync"

	"github.com/google/note-maps/notes"
)

// IDFinder can be implemented in order to provide a notes.Finder through
// ExpandFinder.
type IDFinder interface {
	// FindNoteIDs returns ids: the ID of every note that matches q. If q
	// specifies an ordering, FindNoteIDs should return ids in that order.
	FindNoteIDs(q *notes.Query) (ids []notes.ID, err error)
}

// ExpandFinder combines tf and l to provide a notes.Finder implementation.
func ExpandFinder(tf IDFinder, l notes.Loader) notes.Finder {
	return &finder{tf, l}
}

type finder struct {
	IDFinder
	l notes.Loader
}

func (f *finder) Find(q *notes.Query) ([]notes.GraphNote, error) {
	ids, err := f.FindNoteIDs(q)
	if err != nil {
		return nil, err
	}
	return f.l.Load(ids)
}

// TruncatedLoader can be implemented in order to provide a Loader through
// ExpandLoader.
type TruncatedLoader interface {
	// LoadTruncatedNotes should return tns where len(tns)==len(ids) and, for
	// each offset into ids, tns[offset].ID==ids[offset].
	//
	// Implementations should return notes.InvalidID if any ID in ids is empty.
	//
	// Since all notes implicitly exist, there is no "not found" error: for any
	// ID x where nothing is known about x, implementations should return
	// TruncatedNote{ID:x}.
	LoadTruncatedNotes(ids []notes.ID) (tns []notes.TruncatedNote, err error)
}

// ExpandLoader expands tl into a Loader implementation with a simple built-in
// cache that is suitable for short-lived loaders.
func ExpandLoader(tl TruncatedLoader) notes.Loader {
	return &loader{tl: tl}
}

type loader struct {
	tl    TruncatedLoader
	cache sync.Map
}

func (l *loader) Load(ids []notes.ID) ([]notes.GraphNote, error) {
	var (
		ns    = make([]notes.GraphNote, len(ids))
		q     = ids
		q2ids map[int]int
	)
	for i, id := range ids {
		if id.Empty() {
			return nil, notes.InvalidID
		}
		in, ok := l.cache.Load(id)
		if ok {
			ns[i] = in.(notes.GraphNote)
			if len(q) == len(ids) {
				q = append([]notes.ID{}, ids[:i]...)
				q2ids = make(map[int]int)
			}
		} else if len(q) < len(ids) {
			q2ids[len(q)] = i
			q = append(q, ids[i])
		}
	}
	tns, err := l.tl.LoadTruncatedNotes(q)
	if err != nil {
		return nil, err
	}
	for qi := range tns {
		i, ok := q2ids[qi]
		if !ok {
			i = qi
		}
		in, _ := l.cache.LoadOrStore(ids[i], notes.ExpandNote(tns[qi], l))
		ns[i] = in.(notes.GraphNote)
	}
	return ns, nil
}
