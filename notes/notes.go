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

// Package notes provides types and functions for interacting with a note maps
// data storage system.
package notes

import (
	"io"
)

// TruncatedNote is a minimal representation of a note intended for storage
// integrations and for algorithms that don't need to traverse a graph of
// notes.
type TruncatedNote struct {
	ID          ID
	ValueString string
	ValueType   ID
	Contents    []ID
	Types       []ID
}

// TruncateNote returns a TruncatedNote representation of n.
func TruncateNote(n GraphNote) (TruncatedNote, error) {
	vs, vt, err := n.GetValue()
	if err != nil {
		return TruncatedNote{}, err
	}
	var vtid ID
	if vt != nil {
		vtid = vt.GetID()
	}
	cs, err := n.GetContents()
	if err != nil {
		return TruncatedNote{}, err
	}
	cids := make([]ID, len(cs))
	for i, c := range cs {
		cids[i] = c.GetID()
	}
	ts, err := n.GetTypes()
	if err != nil {
		return TruncatedNote{}, err
	}
	tids := make([]ID, len(ts))
	for i, t := range ts {
		tids[i] = t.GetID()
	}
	return TruncatedNote{
		ID:          n.GetID(),
		ValueString: vs,
		ValueType:   vtid,
		Contents:    cids,
		Types:       tids,
	}, nil
}

// Equals return true if and only if x is deeply equal to y.
func (x TruncatedNote) Equals(y TruncatedNote) bool {
	return x.ID == y.ID &&
		x.ValueString == y.ValueString && x.ValueType == y.ValueType &&
		len(x.Contents) == len(y.Contents) && len(x.Types) == len(y.Types) &&
		IDSlice(x.Contents).PrefixMatch(y.Contents) == len(x.Contents) &&
		IDSlice(x.Types).PrefixMatch(y.Types) == len(x.Types)
}

// Diff produces a set of operations that if applied to a would make it match
// b.
//
// Differences in ID are not considered: a and b are not required to have the
// same ID, and applying the operations to a will not cause it to have the same
// ID as b.
func Diff(a, b TruncatedNote) []Operation {
	var ops OperationSlice
	if a.ValueType != b.ValueType {
		ops = ops.SetValue(a.ID, b.ValueString, b.ValueType)
	} else if a.ValueString != b.ValueString {
		ops = ops.SetValueString(a.ID, b.ValueString)
	}
	ops = ops.PatchContent(a.ID, IDSliceDiff(a.Contents, b.Contents))
	ops = ops.PatchTypes(a.ID, IDSliceDiff(a.Types, b.Types))
	return ops
}

// Patch applies a set of operations to a.
func Patch(a *TruncatedNote, ops []Operation) error {
	for _, op := range ops {
		if !op.AffectsID(a.ID) {
			continue
		}
		switch o := op.(type) {
		case OpSetValue:
			a.ValueString = o.Lexical
			a.ValueType = o.Datatype
		case OpSetValueString:
			a.ValueString = o.Lexical
		case OpContentDelta:
			a.Contents = IDSlice(a.Contents).Apply(o.IDSliceOps)
		case OpTypesDelta:
			a.Types = IDSlice(a.Types).Apply(o.IDSliceOps)
		}
	}
	return nil
}

// GraphNote is a graph-like interface to a note in a note map.
//
// Since traversing from note to note in a note map may require fragile
// operations like loading query results from a storage backend, most methods
// can return an error instead of the requested data.
type GraphNote interface {
	GetID() ID
	GetValue() (string, GraphNote, error)
	GetContents() ([]GraphNote, error)
	GetTypes() ([]GraphNote, error)
}

// ExpandNote uses tn and l to provide a full GraphNote implementation.
func ExpandNote(tn TruncatedNote, l Loader) GraphNote {
	return &loaderNote{tn, l}
}

type loaderNote struct {
	TruncatedNote
	l Loader
}

func (n *loaderNote) GetID() ID { return n.ID }
func (n *loaderNote) GetValue() (string, GraphNote, error) {
	if n.ValueType.Empty() {
		return n.ValueString, EmptyNote(EmptyID), nil
	}
	vtype, err := LoadOne(n.l, n.ValueType)
	return n.ValueString, vtype, err
}
func (n *loaderNote) GetContents() ([]GraphNote, error) {
	return n.l.Load(n.Contents)
}
func (n *loaderNote) GetTypes() ([]GraphNote, error) {
	return n.l.Load(n.Types)
}

// Finder can be implemented to support finding notes in a note map according
// to a query.
type Finder interface {
	Find(*Query) ([]GraphNote, error)
}

// Loader can be implemented to support loading notes by id.
type Loader interface {
	// Load returns a slice of all found notes.
	//
	// All notes exist implicitly, even if they are empty. An error indicates
	// something actually went wrong.
	Load(ids []ID) ([]GraphNote, error)
}

// FindLoader combines the Finder and Loader interfaces.
type FindLoader interface {
	Finder
	Loader
}

// LoadOne is a convenience function for loading just one note.
func LoadOne(l Loader, id ID) (GraphNote, error) {
	ns, err := l.Load([]ID{id})
	if err != nil {
		return nil, err
	}
	return ns[0], nil
}

// Patcher can be implemented to support making changes to notes in a note map
// by applying a set of differences to them.
type Patcher interface {
	Patch(ops []Operation) error
}

// FindLoadPatcher combines the Finder, Loader, and Patcher interfaces.
type FindLoadPatcher interface {
	Finder
	Loader
	Patcher
}

// IsolatedReader provides isolated read operations over a note map.
type IsolatedReader interface {
	// IsolatedRead invokes f with a FindLoader that will read from an
	// unchanging version of the note map.
	IsolatedRead(f func(r FindLoader) error) error
}

// IsolatedWriter provides atomic isolated write operations over a note map.
type IsolatedWriter interface {
	// IsolatedWrite invokes f with an isolated FindLoadPatcher that can read and
	// change a note map.
	//
	// If f returns an error, none of the changes will be saved. Implementations
	// should return an error in any case when changes are not saved.
	IsolatedWrite(f func(rw FindLoadPatcher) error) error
}

// IsolatedReadWriteCloser provides atomic isolated read and write operations
// over a note map.
//
// An instance of IsolatedReadWriteCloser should be closed when it is no longer
// needed.
type IsolatedReadWriteCloser interface {
	IsolatedReader
	IsolatedWriter
	io.Closer
}
