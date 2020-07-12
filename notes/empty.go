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

// EmptyId is the zero or nil value for note identifiers, and never identifies
// a valid note.
//
// EmptyId exists only to make code that specifies the zero value for Note
// identifiers a bit more readable.
const EmptyId uint64 = 0

// EmptyNote is simply an empty Note with nothing more than an Id.
type EmptyNote uint64

func (x EmptyNote) GetId() uint64                   { return uint64(x) }
func (x EmptyNote) GetTypes() ([]Note, error)       { return nil, nil }
func (x EmptyNote) GetSupertypes() ([]Note, error)  { return nil, nil }
func (x EmptyNote) GetValue() (string, Note, error) { return "", EmptyNote(0), nil }
func (x EmptyNote) GetContents() ([]Note, error)    { return nil, nil }

const (
	// EmptyLoader implements the Loader interface for a note map that is
	// always empty.
	EmptyLoader emptyLoader = 0
)

type emptyLoader int

func (x emptyLoader) Load(ids []uint64) ([]Note, error) {
	ns := make([]Note, len(ids))
	for i, id := range ids {
		if id == EmptyId {
			return nil, InvalidId
		}
		ns[i] = EmptyNote(id)
	}
	return ns, nil
}
