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

import "errors"

// Stage describes a set of changes that might be made to a note map.
//
// The default stage describes an empty set of changes to be made to an empty
// note map.
//
// A default Stage{} is an empty set of changes made to an empty note map.
type Stage struct {
	Ops  OperationSlice
	Base Loader
}

// Add simply appends o to the set of operations described by x.
func (x *Stage) Add(o Operation) *Stage {
	x.Ops = append(x.Ops, o)
	return x
}

// Note returns a note-specific StageNote focused on note with id.
func (x *Stage) Note(id ID) *StageNote { return &StageNote{x, id} }

// GetBase returns a non-nil Loader derived from x.Base.
func (x *Stage) GetBase() Loader {
	base := x.Base
	if base == nil {
		base = EmptyLoader
	}
	return base
}

// StageNote supports updating the content of a note within a batch, and also
// implements the GraphNote interface to read the hypothetical state of a note
// with the batch applied.
type StageNote struct {
	Stage *Stage
	ID    ID
}

func (x *StageNote) GetID() ID { return x.ID }
func (x *StageNote) GetValue() (string, GraphNote, error) {
	base, err := LoadOne(x.Stage.GetBase(), x.ID)
	if err != nil {
		return "", nil, err
	}
	lex, dtype, err := base.GetValue()
	if err != nil {
		return lex, dtype, err
	}
	for _, op := range x.Stage.Ops {
		if op.AffectsID(x.ID) {
			switch o := op.(type) {
			case OpSetValue:
				lex, dtype = o.Lexical, x.Stage.Note(o.Datatype)
			}
		}
	}
	return lex, dtype, nil
}

func (x *StageNote) GetContents() ([]GraphNote, error) {
	cids, err := x.GetContentIDs()
	if err != nil {
		return nil, err
	}
	return x.Stage.GetBase().Load(cids)
}
func (x *StageNote) GetContentIDs() ([]ID, error) {
	base, err := LoadOne(x.Stage.GetBase(), x.ID)
	if err != nil {
		return nil, err
	}
	ns, err := base.GetContents()
	if err != nil {
		return nil, err
	}
	cids := make(IDSlice, len(ns))
	for i, n := range ns {
		cids[i] = n.GetID()
	}
	for _, op := range x.Stage.Ops {
		if op.AffectsID(x.ID) {
			switch o := op.(type) {
			case OpContentDelta:
				if !cids.CanApply(o.IDSliceOps) {
					return nil, errors.New("cannot apply delta")
				}
				cids = cids.Apply(o.IDSliceOps)
			}
		}
	}
	return cids, nil
}

func (x *StageNote) GetTypes() ([]GraphNote, error) {
	tids, err := x.GetTypeIDs()
	if err != nil {
		return nil, err
	}
	return x.Stage.GetBase().Load(tids)
}
func (x *StageNote) GetTypeIDs() ([]ID, error) {
	base, err := LoadOne(x.Stage.GetBase(), x.ID)
	if err != nil {
		return nil, err
	}
	ns, err := base.GetTypes()
	if err != nil {
		return nil, err
	}
	tids := make(IDSlice, len(ns))
	for i, n := range ns {
		tids[i] = n.GetID()
	}
	for _, op := range x.Stage.Ops {
		if op.AffectsID(x.ID) {
			switch o := op.(type) {
			case OpTypesDelta:
				if !tids.CanApply(o.IDSliceOps) {
					return nil, errors.New("cannot apply delta")
				}
				tids = tids.Apply(o.IDSliceOps)
			}
		}
	}
	return tids, nil
}

// Note returns the identified note from the underlying stage.
func (x *StageNote) Note(id ID) *StageNote { return x.Stage.Note(id) }

// SetValue expands the staged operations to update the value of this note.
func (x *StageNote) SetValue(lexical string, datatype ID) error {
	if x.ID == EmptyID {
		panic("cannot set value before specifying an ID")
	}
	x.Stage.Ops = x.Stage.Ops.SetValue(x.ID, lexical, datatype)
	return nil
}

// AddContent expands the staged operations to add content to this note.
func (x *StageNote) AddContent(id ID) (*StageNote, error) {
	if x.ID == EmptyID {
		panic("cannot add content before specifying an ID")
	}
	cids, err := x.GetContentIDs()
	if err != nil {
		return nil, err
	}
	x.Stage.Ops = x.Stage.Ops.PatchContent(x.ID, IDSlice(cids).Append(id))
	return &StageNote{x.Stage, id}, nil
}

// AddContent expands the staged operations to add content to this note.
func (x *StageNote) InsertTypes(i int, add ...ID) error {
	if x.ID == EmptyID {
		panic("cannot set types before specifying an ID")
	}
	tids, err := x.GetTypeIDs()
	if err != nil {
		return err
	}
	x.Stage.Ops = x.Stage.Ops.PatchTypes(x.ID, IDSlice(tids).Append(add...))
	return nil
}

func MustStageNote(n *StageNote, err error) *StageNote {
	if err != nil {
		panic(err)
	}
	return n
}
