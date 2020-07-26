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

package runes

import "testing"

const (
	TestRune0 rune = 'a'
	TestRune1      = 'b'
	TestRune2      = 'c'
	TestRune3      = 'd'
	TestRune4      = 'e'
)

func TestString_String(t *testing.T) {
	// This is kind of a silly test to help hit 100% test coverage, but keeping
	// coverage at 100% is worth being a bit silly if that's what it takes to
	// make 99% coverage stand out.
	if actual := String("test").String(); actual != "test" {
		t.Errorf("got %#v, expected %#v", actual, "test")
	}
}
