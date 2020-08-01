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

// Package note provides types and functions for interacting with a note maps
// data storage system.
package note

import (
	"math/rand"
	"strconv"
)

//go:generate go run generate_id_ot.go

type String []rune

func (xs String) String() string { return string(xs) }

// ID is the type of values that identify note.
type ID string

// RandomID returns a pseudo-random ID using package math/rand.
func RandomID() ID {
	return ID(strconv.FormatUint(rand.Uint64(), 10))
}

func (x ID) String() string { return string(x) }

type IDSlice []ID

func (ids IDSlice) String() string {
	s := "["
	for i, id := range ids {
		if i > 0 {
			s += ","
		}
		s += string(id)
	}
	return s + "]"
}
