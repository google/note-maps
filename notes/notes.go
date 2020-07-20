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

// ID is the type of values that identify notes.
type ID string

// Note is a graph-like interface to a note in a note map.
//
// Since traversing from note to note in a note map may require fragile
// operations like loading query results from a storage backend, most methods
// can return an error instead of the requested data.
type Note interface {
	GetID() ID
	GetValue() (string, Note, error)
	GetContents() ([]Note, error)
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
	// All notes exist implicitly, even if they are empty. An error indicates
	// something actually went wrong.
	Load(ids []ID) ([]Note, error)
}

// FindLoader combines the Finder and Loader interfaces.
type FindLoader interface {
	Finder
	Loader
}

// LoadOne is a convenience function for loading just one note.
func LoadOne(l Loader, id ID) (Note, error) {
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
