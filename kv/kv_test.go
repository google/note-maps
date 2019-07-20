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

package kv

import (
	"testing"
)

func TestEntityEncodeDecode(t *testing.T) {
	for _, want := range []Entity{0, 42, 0x0123456789ABCDEF} {
		var (
			e   Encoder = want
			got Entity
			d   Decoder = &got
		)
		if err := d.Decode(e.Encode()); err != nil {
			t.Error("want", want, "got", err)
		} else if want != got {
			t.Error("want", want, "got", got)
		}
	}
}

func TestEntitySliceEncodeDecode(t *testing.T) {
	for _, want := range []EntitySlice{
		{},
		{42},
		{0, 42, 0x0123456789ABCDEF},
	} {
		var (
			e   Encoder = want
			got EntitySlice
			d   Decoder = &got
		)
		if err := d.Decode(e.Encode()); err != nil {
			t.Error("want", want, "got", err)
		} else if !want.Equal(got) {
			t.Error("want", want, "got", got)
		}
	}
}

func TestEntitySliceEqual(t *testing.T) {
	for _, test := range [][2]EntitySlice{
		{{42}, {0, 42}},
		{{42, 43}, {0, 42}},
	} {
		if test[0].Equal(test[1]) {
			t.Error("want test[0].Equal(test[1])==false, got true")
		}
		if test[1].Equal(test[0]) {
			t.Error("want test[1].Equal(test[0])==false, got true")
		}
	}
}

func TestEntitySliceSortInsert(t *testing.T) {
	for _, test := range []struct {
		In, Out  EntitySlice
		Insert   []Entity
		Inserted []bool
	}{
		{
			Insert:   []Entity{42, 0, 0, 42},
			Inserted: []bool{true, true, false, false},
			Out:      EntitySlice{0, 42},
		},
		{
			In:       EntitySlice{42},
			Insert:   []Entity{0xfedcba9876543210, 0},
			Inserted: []bool{true, true},
			Out:      EntitySlice{0, 42, 0xfedcba9876543210},
		},
		{
			In:       EntitySlice{0xfedcba9876543210, 42, 0},
			Insert:   []Entity{2, 42},
			Inserted: []bool{true, false},
			Out:      EntitySlice{0, 2, 42, 0xfedcba9876543210},
		},
	} {
		test.In.Sort()
		for i, x := range test.Insert {
			if test.In.Insert(x) != test.Inserted[i] {
				t.Errorf("want Insert(%v)==%v, got %v",
					x, !test.Inserted[i], test.Inserted[i])
			}
		}
		if !test.In.Equal(test.Out) {
			t.Error("want", test.Out, "got", test.In)
		}
	}
}

func TestEntitySliceSortRemove(t *testing.T) {
	for _, test := range []struct {
		In, Out EntitySlice
		Remove  []Entity
		Removed []bool
	}{
		{
			Remove:  []Entity{42},
			Removed: []bool{false},
			Out:     EntitySlice{},
		},
		{
			In:      EntitySlice{42},
			Remove:  []Entity{0xfedcba9876543210, 0},
			Removed: []bool{false, false},
			Out:     EntitySlice{42},
		},
		{
			In:      EntitySlice{0xfedcba9876543210, 42, 0},
			Remove:  []Entity{2, 42},
			Removed: []bool{false, true},
			Out:     EntitySlice{0, 0xfedcba9876543210},
		},
	} {
		test.In.Sort()
		for i, x := range test.Remove {
			if test.In.Remove(x) != test.Removed[i] {
				t.Errorf("want %v.Remove(%v)==%v, got %v",
					test.In, x, !test.Removed[i], test.Removed[i])
			}
		}
		if !test.In.Equal(test.Out) {
			t.Error("want", test.Out, "got", test.In)
		}
	}
}

func TestStringEncodeDecode(t *testing.T) {
	for _, want := range []String{"", "Hello, World!", "0x0123456789ABCDEF"} {
		var (
			e   Encoder = want
			got String
			d   Decoder = &got
		)
		if err := d.Decode(e.Encode()); err != nil {
			t.Error("want", want, "got", err)
		} else if want != got {
			t.Error("want", want, "got", got)
		}
	}
}
