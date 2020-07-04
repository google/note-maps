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
	"sync"

	"github.com/google/note-maps/notes"
	"github.com/google/note-maps/notes/pbdb/pb"
)

// Finder implements github.com/google/note-maps/notes.Finder.
type finder struct {
	r DbReader
}

func NewFinder(r DbReader) notes.Finder { return &finder{r} }

func (f finder) Find(q *notes.Query) ([]notes.Note, error) {
	ids, err := f.r.Find(q)
	if err != nil {
		return nil, err
	}
	ns := make([]notes.Note, len(ids))
	for i, id := range ids {
		ns[i] = &note{
			r:  f.r,
			id: id,
		}
	}
	return ns, nil
}

type note struct {
	mx sync.Mutex
	r  DbReader
	id uint64
	p  *pb.Note
}

func (n *note) GetId() uint64 { return n.id }

func (n *note) init() error {
	n.mx.Lock()
	defer n.mx.Unlock()
	if n.p == nil {
		if ps, err := n.r.Load(n.id); err != nil {
			return err
		} else {
			n.p = ps[0]
		}
	}
	return nil
}

func (n *note) load(ids []uint64) ([]notes.Note, error) {
	ps, err := n.r.Load(ids...)
	if err != nil {
		return nil, err
	}
	ns := make([]notes.Note, len(ps))
	for i, p := range ps {
		ns[i] = &note{r: n.r, id: p.GetId()}
	}
	return ns, err
}

func (n *note) GetTypes() (ns []notes.Note, err error) {
	if err = n.init(); err != nil {
		return nil, err
	}
	return n.load(n.p.GetTypes())
}
func (n *note) GetSupertypes() (ns []notes.Note, err error) {
	if err = n.init(); err != nil {
		return nil, err
	}
	return n.load(n.p.GetSupertypes())
}
func (n *note) GetValue() (s string, dt notes.Note, err error) {
	if err = n.init(); err != nil {
		return
	}
	s = n.p.Value.GetLexical()
	dtid := n.p.GetValue().GetDatatype()
	if dtid != 0 {
		dt = &note{r: n.r, id: dtid}
	}
	return
}
func (n *note) GetContents() ([]notes.Note, error) {
	if err := n.init(); err != nil {
		return nil, err
	}
	return n.load(n.p.GetContents())
}
