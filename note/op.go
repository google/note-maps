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

package note

import "github.com/google/note-maps/otgen/runes"

// Operation is implemented by types that can describe changes that might be
// made to a note map.
type Operation interface {
	AffectsID(id ID) bool
}

type OperationSlice []Operation

// Op is a minimal implementation of Operation meant to be used as a mixin for
// operations that affect only one note.
type Op ID

// AffectsID returns true if x could change a note with ID==id.
func (x Op) AffectsID(id ID) bool { return ID(x) == id }
func (x Op) GetID() ID            { return ID(x) }

// OpSetValue sets the value and data type of a note to Lexical and Datatype.
type OpSetValue struct {
	Op
	Lexical  string
	Datatype ID
}

// SetValue returns a new OperationSlice that also sets the value and type of
// note id to vs and vt.
func (os OperationSlice) SetValue(id ID, vs string, vt ID) OperationSlice {
	return append(os, OpSetValue{Op(id), vs, vt})
}

func (os OpSetValue) String() string {
	return "set value of " + string(os.Op) +
		" to type " + string(os.Datatype) +
		" and value " + os.Lexical
}

// OpSetValueString sets the value of a note to Lexical.
type OpSetValueString struct {
	Op
	Lexical string
}

func (os OpSetValueString) String() string {
	return "set value of " + string(os.Op) + " to " + os.Lexical
}

// SetValue returns a new OperationSlice that also sets the value of note id to vs.
func (os OperationSlice) SetValueString(id ID, vs string) OperationSlice {
	return append(os, OpSetValueString{Op(id), vs})
}

type OpIDSliceDelta struct {
	Op
	IDSliceOps []IDSliceOp
}

func (o OpIDSliceDelta) String() string {
	s := " of " + string(o.Op) + ":"
	for _, op := range o.IDSliceOps {
		s += " " + op.String()
	}
	return s + "."
}

type OpContentDelta OpIDSliceDelta

func (o OpContentDelta) String() string { return "patch content" + OpIDSliceDelta(o).String() }

// InsertContent returns a new OperationSlice that also inserts cs to the
// contents of note id at index.
func (os OperationSlice) InsertContent(id ID, index int, cs ...ID) OperationSlice {
	if len(cs) == 0 {
		return os
	}
	return append(os, OpContentDelta{Op(id), IDSlice{}.Insert(index, cs...)})
}

// PatchContent returns a new OperationSlice that also applies ops to the
// contents of note id.
func (os OperationSlice) PatchContent(id ID, ops []IDSliceOp) OperationSlice {
	if len(ops) == 0 {
		return os
	}
	return append(os, OpContentDelta{Op(id), ops})
}

type OpTypesDelta OpIDSliceDelta

func (o OpTypesDelta) String() string { return "patch types" + OpIDSliceDelta(o).String() }

// PatchTypes returns a new OperationSlice that also applies ops to the types
// of note id.
func (os OperationSlice) PatchTypes(id ID, ops []IDSliceOp) OperationSlice {
	if len(ops) == 0 {
		return os
	}
	return append(os, OpTypesDelta{Op(id), ops})
}

type NoteOp interface{}
type NoteDelta []NoteOp
type NoteOpID ID
type NoteOpValueDelta runes.StringDelta
type NoteOpValueTypeDelta ID
type NoteOpContentsDelta IDSliceDelta
type NoteOpTypesDelta IDSliceDelta

func NoteDeltaFromTruncatedNote(n TruncatedNote) NoteDelta {
	return NoteDelta{}.
		ChangeValueType(n.ValueType).
		ChangeValueString(runes.String("").Append([]rune(n.ValueString)...)).
		ChangeContents(IDSlice{}.Append(n.Contents...)).
		ChangeTypes(IDSlice{}.Append(n.Types...))
}
func (xs NoteDelta) GetID() ID {
	id := EmptyID
	for _, x := range xs {
		switch o := x.(type) {
		case NoteOpID:
			id = ID(o)
		}
	}
	return id
}
func (xs NoteDelta) GetValueTypeID() ID {
	vt := EmptyID
	for _, x := range xs {
		switch o := x.(type) {
		case NoteOpValueTypeDelta:
			vt = ID(o)
		}
	}
	return vt
}
func (xs NoteDelta) GetValueString() runes.String {
	var vs runes.String
	for _, x := range xs {
		switch o := x.(type) {
		case NoteOpValueDelta:
			vs = vs.Apply(runes.StringDelta(o))
		}
	}
	return vs
}
func (xs NoteDelta) GetContentIDs() IDSlice {
	var ids IDSlice
	for _, x := range xs {
		switch o := x.(type) {
		case NoteOpContentsDelta:
			ids = ids.Apply(IDSliceDelta(o))
		}
	}
	return ids
}
func (xs NoteDelta) GetTypeIDs() IDSlice {
	var ids IDSlice
	for _, x := range xs {
		switch o := x.(type) {
		case NoteOpTypesDelta:
			ids = ids.Apply(IDSliceDelta(o))
		}
	}
	return ids
}
func (xs NoteDelta) Truncate() TruncatedNote {
	return TruncatedNote{
		ID:          xs.GetID(),
		ValueString: xs.GetValueString().String(),
		ValueType:   xs.GetValueTypeID(),
		Contents:    xs.GetContentIDs(),
		Types:       xs.GetTypeIDs(),
	}
}
func (xs NoteDelta) SetID(id ID) NoteDelta {
	return append(xs, NoteOpID(id))
}
func (xs NoteDelta) ChangeValueType(vt ID) NoteDelta {
	return append(xs, NoteOpValueTypeDelta(vt))
}
func (xs NoteDelta) ChangeValueString(d runes.StringDelta) NoteDelta {
	return append(xs, NoteOpValueDelta(d))
}
func (xs NoteDelta) ChangeContents(d IDSliceDelta) NoteDelta {
	return append(xs, NoteOpContentsDelta(d))
}
func (xs NoteDelta) ChangeTypes(d IDSliceDelta) NoteDelta {
	return append(xs, NoteOpTypesDelta(d))
}

type NoteMapOp interface{}
type NoteMapOpNoteDelta NoteDelta
type NoteMapDelta []NoteMapOp

func (xs NoteMapDelta) ChangeNote(n NoteDelta) NoteMapDelta {
	return append(xs, NoteMapOpNoteDelta(n))
}
