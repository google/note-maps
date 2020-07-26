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

package notes

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
	return "set " + string(os.Op) + " value type " + string(os.Datatype) + " and value " + os.Lexical
}

// OpSetValueString sets the value of a note to Lexical.
type OpSetValueString struct {
	Op
	Lexical string
}

func (os OpSetValueString) String() string {
	return "set " + string(os.Op) + " value to " + os.Lexical
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
	s := "ids patch for " + string(o.Op) + ":"
	for _, op := range o.IDSliceOps {
		s += " " + op.String()
	}
	return s + "."
}

type OpContentDelta OpIDSliceDelta

func (o OpContentDelta) String() string { return "content " + OpIDSliceDelta(o).String() }

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

func (o OpTypesDelta) String() string { return "types " + OpIDSliceDelta(o).String() }

// PatchTypes returns a new OperationSlice that also applies ops to the types
// of note id.
func (os OperationSlice) PatchTypes(id ID, ops []IDSliceOp) OperationSlice {
	if len(ops) == 0 {
		return os
	}
	return append(os, OpTypesDelta{Op(id), ops})
}
