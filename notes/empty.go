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

// EmptyID is the zero or nil value for note identifiers, and never identifies
// a valid note.
//
// EmptyID exists only to make code that specifies the zero value for note
// identifiers a bit more readable.
const EmptyID ID = ""

func (id ID) Empty() bool { return id == EmptyID }

// EmptyNote is simply an empty GraphNote with nothing more than an ID.
type EmptyNote ID

func (x EmptyNote) GetID() ID                            { return ID(x) }
func (x EmptyNote) GetValue() (string, GraphNote, error) { return "", EmptyNote(EmptyID), nil }
func (x EmptyNote) GetContents() ([]GraphNote, error)    { return nil, nil }
func (x EmptyNote) GetTypes() ([]GraphNote, error)       { return nil, nil }

const (
	// EmptyLoader implements the Loader interface for a note map that is
	// always empty.
	EmptyLoader emptyLoader = 0
)

type emptyLoader int

func (x emptyLoader) Load(ids []ID) ([]GraphNote, error) {
	ns := make([]GraphNote, len(ids))
	for i, id := range ids {
		if id == EmptyID {
			return nil, InvalidID
		}
		ns[i] = EmptyNote(id)
	}
	return ns, nil
}
