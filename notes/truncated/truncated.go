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

// TruncatedNote is a minimal representation of a note that can simplify the
// implementation of the Loader and Finder interfaces.
type TruncatedNote struct {
	ID          notes.ID
	ValueString string
	ValueType   notes.ID
	Contents    []notes.ID
}

// ExpandNote uses tn and l to provide a full notes.Note implementation.
func ExpandNote(tn TruncatedNote, l notes.Loader) notes.Note {
	return &note{tn, l}
}

type note struct {
	TruncatedNote
	l notes.Loader
}

func (n *note) GetID() notes.ID { return n.ID }
func (n *note) GetValue() (string, notes.Note, error) {
	if n.ValueType.Empty() {
		return n.ValueString, notes.EmptyNote(notes.EmptyID), nil
	}
	vtype, err := notes.LoadOne(n.l, n.ValueType)
	return n.ValueString, vtype, err
}
func (n *note) GetContents() ([]notes.Note, error) {
	return n.l.Load(n.Contents)
}

// IDFinder can be implemented in order to provide a notes.Finder through
// ExpandFinder.
type IDFinder interface {
	FindNoteIDs(*notes.Query) ([]notes.ID, error)
}

// ExpandFinder combines tf and l to provide a full notes.Finder
// implementation.
func ExpandFinder(tf IDFinder, l notes.Loader) notes.Finder {
	return &finder{tf, l}
}

type finder struct {
	IDFinder
	l notes.Loader
}

func (f *finder) Find(q *notes.Query) ([]notes.Note, error) {
	ids, err := f.FindNoteIDs(q)
	if err != nil {
		return nil, err
	}
	return f.l.Load(ids)
}

// TruncatedLoader can be implemented in order to provide a Loader through
// ExpandLoader.
type TruncatedLoader interface {
	LoadTruncatedNotes([]notes.ID) ([]TruncatedNote, error)
}

// ExpandLoader expands tl into a full Loader implementation with built-in
// caching.
func ExpandLoader(tl TruncatedLoader) notes.Loader {
	return &loader{tl: tl}
}

type loader struct {
	tl    TruncatedLoader
	cache sync.Map
}

func (l *loader) Load(ids []notes.ID) ([]notes.Note, error) {
	var (
		ns    = make([]notes.Note, len(ids))
		q     = ids
		q2ids map[int]int
	)
	for i, id := range ids {
		in, ok := l.cache.Load(id)
		if ok {
			ns[i] = in.(notes.Note)
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
		in, _ := l.cache.LoadOrStore(ids[i], ExpandNote(tns[qi], l))
		ns[i] = in.(notes.Note)
	}
	return ns, nil
}
