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

package pbdb

import (
	"github.com/google/note-maps/notes"
	"github.com/google/note-maps/notes/change"
	"github.com/google/note-maps/notes/pbdb/pb"
)

type patcher struct{ w DbReadWriter }

func (x patcher) Patch(ops []change.Operation) error {
	ns := make(map[uint64]notes.Note)
	for _, op := range ops {
		switch o := op.(type) {
		case change.SetValue:
			ns[o.Id] = nil
		case change.AddContent:
			ns[o.Id] = nil
		default:
			panic("operation unknown")
		}
	}
	ids := make([]uint64, 0, len(ns))
	for id := range ns {
		if id == 0 {
			return notes.InvalidId
		}
		ids = append(ids, id)
	}
	ps, err := x.w.Load(ids...)
	if err != nil {
		return err
	}
	stage := notes.Stage{Base: loader{x.w}, Ops: ops}
	for _, p := range ps {
		n := stage.Note(p.Id)
		s, dt, err := n.GetValue()
		if err != nil {
			return err
		}
		if s != "" {
			p.Value = &pb.Note_Value{
				Lexical:  s,
				Datatype: dt.GetId(),
			}
		}
		cs, err := n.GetContents()
		if err != nil {
			return err
		}
		for _, c := range cs {
			p.Contents = append(p.Contents, c.GetId())
		}
	}
	return x.w.Store(ps)
}
