// Copyright 2019 Google LLC
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

package kvtest

import (
	"fmt"
	"math/rand"
	"testing"

	"github.com/google/note-maps/kv"
)

func TestNew(t *testing.T) {
	s := New(t)
	defer s.Discard()
	if s == nil {
		t.Fatal("New return nil")
	}
}

type flakyMethod int

const (
	Alloc flakyMethod = iota
	Get
	Set
	FlakyMethodCount
)

func randMethods(n int) []flakyMethod {
	ms := make([]flakyMethod, n)
	for i := range ms {
		ms[i] = flakyMethod(rand.Int()) % FlakyMethodCount
	}
	return ms
}

func randBytes(n int) []byte {
	ms := make([]byte, n)
	for i := range ms {
		ms[i] = byte(rand.Int() % 256)
	}
	return ms
}

func callMethod(s kv.Txn, m flakyMethod) error {
	switch m {
	case Alloc:
		_, err := s.Alloc()
		return err
	case Get:
		err := s.Get(randBytes(4), func([]byte) error { return nil })
		return err
	case Set:
		err := s.Set(randBytes(4), randBytes(32))
		return err
	default:
		panic(fmt.Sprintf("unrecognized flakyMethod %v", m))
	}
}

func TestFlakyDeflake(t *testing.T) {
	var (
		ms   = randMethods(10)
		test = func(s kv.Txn) {
			for _, m := range ms {
				if err := callMethod(s, m); err != nil {
					panic(err)
				}
			}
		}
	)
	Deflake(t, test)
}
