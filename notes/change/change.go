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

package change

type Operation interface {
	AffectsId(id uint64) bool
}

type SetValue struct {
	Id       uint64
	Lexical  string
	Datatype uint64
}

func (x SetValue) AffectsId(id uint64) bool { return x.Id == id }

type AddContent struct {
	Id  uint64
	Add uint64
}

func (x AddContent) AffectsId(id uint64) bool { return x.Id == id }
