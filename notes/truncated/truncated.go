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

// TruncatedNote is a minimal representation of a note.
type TruncatedNote struct {
	ID          notes.ID
	ValueString string
	ValueType   notes.ID
	Contents    []notes.ID
}

// TruncateNote returns a TruncatedNote representation of n.
func TruncateNote(n notes.GraphNote) (TruncatedNote, error) {
	vs, vt, err := n.GetValue()
	if err != nil {
		return TruncatedNote{}, err
	}
	var vtid notes.ID
	if vt != nil {
		vtid = vt.GetID()
	}
	cs, err := n.GetContents()
	if err != nil {
		return TruncatedNote{}, err
	}
	cids := make([]notes.ID, len(cs))
	for i, c := range cs {
		cids[i] = c.GetID()
	}
	return TruncatedNote{
		ID:          n.GetID(),
		ValueString: vs,
		ValueType:   vtid,
		Contents:    cids,
	}, nil
}

// ExpandNote uses tn and l to provide a full notes.GraphNote implementation.
func ExpandNote(tn TruncatedNote, l notes.Loader) notes.GraphNote {
	return &note{tn, l}
}

// Equals return true if and only if x is deeply equal to y.
func (x TruncatedNote) Equals(y TruncatedNote) bool {
	eq := x.ID == y.ID &&
		x.ValueString == y.ValueString && x.ValueType == y.ValueType &&
		len(x.Contents) == len(y.Contents)
	if !eq {
		return false
	}
	for i, xc := range x.Contents {
		if y.Contents[i] != xc {
			return false
		}
	}
	return true
}

// Diff produces a set of operations that if applied to a would make it match
// b.
//
// Differences in ID are not considered: a and b are not required to have the
// same ID, and applying the operations to a will not cause it to have the same
// ID as b.
func Diff(a, b TruncatedNote) []notes.Operation {
	var ops notes.OperationSlice
	if a.ValueType != b.ValueType {
		ops = ops.SetValue(a.ID, b.ValueString, b.ValueType)
	} else if a.ValueString != b.ValueString {
		ops = ops.SetValueString(a.ID, b.ValueString)
	}
	// assumption: an ID cannot occur twice in the same note's contents, but can
	// be present in multiple notes.
	acm := make(map[notes.ID]bool)
	for _, c := range a.Contents {
		acm[c] = true
	}
	res := append([]notes.ID{}, a.Contents...)
	is := make(map[notes.ID]int)
	for i, c := range b.Contents {
		if !acm[c] {
			// c is in b but not in a, add it to a.
			if i >= len(a.Contents) {
				ops = ops.AddContent(a.ID, c)
				res = append(res, c)
			} else {
				ops = ops.InsertContent(a.ID, i, c)
				res = append(res, c)
				copy(res[i+1:], res[i:len(res)-1])
				res[i] = c
			}
		}
		is[c] = i
	}
	for i0, c := range a.Contents {
		_, ok := is[c]
		if !ok {
			// c is in a but not in b, remove it from a.
			ops = ops.RemoveContent(a.ID, c)
			res = append(res[:i0], res[i0+1:]...)
		}
	}
	if len(res) != len(b.Contents) {
		panic("unintended: res is not the same size as b")
	}
	for i0 := range b.Contents {
		i1, ok := is[res[i0]]
		if !ok {
			panic("unintended: res contains c that is not in b")
		}
		if i0 != i1 {
			ops = ops.SwapContent(a.ID, i0, i1)
			res[i0], res[i1] = res[i1], res[i0]
		}
	}
	return ops
}

// Patch applies a set of operations to a.
func Patch(a *TruncatedNote, ops []notes.Operation) error {
	for _, op := range ops {
		if !op.AffectsID(a.ID) {
			continue
		}
		switch o := op.(type) {
		case notes.OpSetValue:
			a.ValueString = o.Lexical
			a.ValueType = o.Datatype
		case notes.OpSetValueString:
			a.ValueString = o.Lexical
		case notes.OpAddContent:
			a.Contents = append(a.Contents, o.Add)
		case notes.OpInsertContent:
			a.Contents = append(a.Contents, o.Content)
			copy(a.Contents[o.Index+1:], a.Contents[o.Index:len(a.Contents)-1])
			a.Contents[o.Index] = o.Content
		case notes.OpRemoveContent:
			for i, c := range a.Contents {
				if c == o.Content {
					a.Contents = append(a.Contents[:i], a.Contents[i+1:]...)
				}
			}
		case notes.OpSwapContent:
			a.Contents[o.A], a.Contents[o.B] = a.Contents[o.B], a.Contents[o.A]
		}
	}
	return nil
}

type note struct {
	TruncatedNote
	l notes.Loader
}

func (n *note) GetID() notes.ID { return n.ID }
func (n *note) GetValue() (string, notes.GraphNote, error) {
	if n.ValueType.Empty() {
		return n.ValueString, notes.EmptyNote(notes.EmptyID), nil
	}
	vtype, err := notes.LoadOne(n.l, n.ValueType)
	return n.ValueString, vtype, err
}
func (n *note) GetContents() ([]notes.GraphNote, error) {
	return n.l.Load(n.Contents)
}

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
	LoadTruncatedNotes(ids []notes.ID) (tns []TruncatedNote, err error)
}

// ExpandLoader expands tl into a Loader implementation with a simple built-in
// cache.
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
		in, _ := l.cache.LoadOrStore(ids[i], ExpandNote(tns[qi], l))
		ns[i] = in.(notes.GraphNote)
	}
	return ns, nil
}
