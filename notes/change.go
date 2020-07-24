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

type Operation interface {
	AffectsID(id ID) bool
}

type SetValue struct {
	ID       ID
	Lexical  string
	Datatype ID
}

func (x SetValue) AffectsID(id ID) bool { return x.ID == id }

type AddContent struct {
	ID  ID
	Add ID
}

func (x AddContent) AffectsID(id ID) bool { return x.ID == id || x.Add == id }

type Op struct{ ID }

func (x Op) AffectsID(id ID) bool { return x.ID == id }

type OpSetValueString struct {
	Op
	Lexical string
}

type OpInsertContent struct {
	Op
	Content ID
	Index   int
}

type OpRemoveContent struct {
	Op
	Content ID
}

type OpSwapContent struct {
	Op
	A, B int
}
