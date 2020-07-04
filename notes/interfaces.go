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

	"github.com/google/note-maps/notes/change"
)

// NoteMap can be implemented to support finding and patching notes in a note map.
//
// An instance of DB should be closed when it is no longer needed.
type NoteMap interface {
	Finder
	Loader
	Patcher
	io.Closer
}

// Finder can be implemented to support finding notes in a note map according
// to a query.
type Finder interface {
	Find(*Query) ([]Note, error)
}

// Loader can be implemented to support loading notes by id.
type Loader interface {
	// Load returns a slice of all found notes.
	//
	// If the error is NotFound, the returned notes includes all found
	// notes and NotFound.Ids holds the ids of notes that were not found.
	Load(ids []uint64) ([]Note, error)
}

// LoadOne is a convenience function for loading just one note.
func LoadOne(l Loader, id uint64) (Note, error) {
	ns, err := l.Load([]uint64{id})
	if err != nil {
		return nil, err
	}
	return ns[0], nil
}

// Note is a graph-like interface to a note in a note map.
//
// Since traversing from note to note in a note map may require fragile
// operations like loading query results from a storage backend, most methods
// can return an error instead of the requested data.
type Note interface {
	GetId() uint64
	GetTypes() ([]Note, error)
	GetSupertypes() ([]Note, error)
	GetValue() (string, Note, error)
	GetContents() ([]Note, error)
}

// Patcher can be implemented to support making changes to notes in a note map
// by applying a set of differences to them.
type Patcher interface {
	Patch(ops []change.Operation) error
}
