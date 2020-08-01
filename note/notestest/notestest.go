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

package notestest

import (
	"testing"

	"github.com/google/note-maps/note"
)

// Equal returns true only if a and b have the same ID, value, and contents.
func Equal(t *testing.T, a, b note.GraphNote) bool {
	if a == b {
		return true
	}
	if a.GetID() != b.GetID() {
		return false
	}
	sa, err := note.TruncateNote(a)
	if err != nil {
		t.Error(a.GetID(), err)
		return false
	}
	sb, err := note.TruncateNote(b)
	if err != nil {
		t.Error(b.GetID(), err)
		return false
	}
	return sa.Equals(sb)
}

// ExpectEqual emits a detailed diff as a test error if a and b are not equal.
func ExpectEqual(t *testing.T, a, b note.GraphNote) bool {
	if !Equal(t, a, b) {
		if a.GetID() != b.GetID() {
			t.Error("expected equal notes, got IDs", a.GetID(), b.GetID())
		}
		for _, op := range Diff(t, a, b) {
			t.Error("expected equal notes, but must", op)
		}
		return false
	}
	return true
}

// Diff returns a sequence of operations that could be applied to a to make its
// value and contents match b.
func Diff(t *testing.T, a, b note.GraphNote) []note.Operation {
	if a == b {
		return nil
	}
	sa, err := note.TruncateNote(a)
	if err != nil {
		t.Error(err)
		return nil
	}
	sb, err := note.TruncateNote(b)
	if err != nil {
		t.Error(err)
		return nil
	}
	return note.Diff(sa, sb)
}
