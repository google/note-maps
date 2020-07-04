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

// Package pbdb provides types and functions for storing note maps using a
// small number of protocol buffer message types.
package pbdb

import (
	"io"

	"github.com/google/note-maps/notes"
	"github.com/google/note-maps/notes/change"
	"github.com/google/note-maps/notes/pbdb/pb"
)

// DbReader finds and loads pb.Note messages.
type DbReader interface {
	Find(q *notes.Query) ([]uint64, error)
	Load(id ...uint64) ([]*pb.Note, error)
}

// DbReader stores and removes pb.Note messages.
type DbReadWriter interface {
	DbReader
	Store([]*pb.Note) error
	Delete([]uint64) error
}

type DbReaderTransaction interface {
	DbReader
	Discard()
}

type DbReadWriterTransaction interface {
	DbReaderTransaction
	DbReadWriter
	Commit() error
}

type Db interface {
	NewReaderTransaction() DbReaderTransaction
	NewReadWriterTransaction() DbReadWriterTransaction
	io.Closer
}

type notemap struct {
	db Db
}

func NewNoteMap(db Db) notes.NoteMap { return notemap{db} }

func (nm notemap) Find(q *notes.Query) ([]notes.Note, error) {
	t := nm.db.NewReaderTransaction()
	defer t.Discard()
	return finder{t}.Find(q)
}

func (nm notemap) Load(ids []uint64) ([]notes.Note, error) {
	t := nm.db.NewReaderTransaction()
	defer t.Discard()
	return loader{t}.Load(ids)
}

func (nm notemap) Patch(ops []change.Operation) error {
	t := nm.db.NewReadWriterTransaction()
	defer t.Discard()
	err := patcher{t}.Patch(ops)
	if err == nil {
		t.Commit()
	}
	return err
}

func (nm notemap) Close() error { return nm.db.Close() }
