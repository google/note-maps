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

import (
	"reflect"
	"testing"
)

func TestIDSlice_Apply(t *testing.T) {
	for _, test := range []struct {
		In       IDSlice
		Ops      []IDSliceOp
		Out      IDSlice
		CanApply bool
	}{
		{
			In:       IDSlice{"a"},
			Ops:      []IDSliceOp{IDSliceOpRetain(1)},
			CanApply: true,
			Out:      IDSlice{"a"},
		},
	} {
		apply := test.In.CanApply(test.Ops)
		if apply != test.CanApply {
			t.Error("got apply=", apply, "expected apply=", test.CanApply)
		}
		if !apply {
			continue
		}
		out := test.In.Apply(test.Ops)
		if !reflect.DeepEqual(out, test.Out) {
			t.Error("got", out, "expected", test.Out)
		}
	}
}

func TestIDSlice_Diff_andApply(t *testing.T) {
	for _, test := range []struct {
		N      string
		A, B   IDSlice
		LenOps int
	}{
		{"insert", IDSlice{}, IDSlice{"a"}, 1},
		{"delete", IDSlice{"a"}, IDSlice{}, 1},
		{"retain", IDSlice{"a"}, IDSlice{"a"}, 1},
		{"insert, delete", IDSlice{"a"}, IDSlice{"b"}, 2},
		{"delete, retain", IDSlice{"a", "b", "c"}, IDSlice{"b", "c"}, 2},
		{"retain, delete", IDSlice{"a", "b", "c"}, IDSlice{"a", "b"}, 2},
		{"retain, delete, insert, retain", IDSlice{"a", "b", "c"}, IDSlice{"a", "d", "c"}, 4},
	} {
		t.Run(test.N, func(t *testing.T) {
			diff := test.A.Diff(test.B)
			if len(diff) != test.LenOps {
				t.Error("got", diff, "with len", len(diff), "expected len", test.LenOps)
			}
			if !test.A.CanApply(diff) {
				t.Error("cannot apply diff")
			} else {
				actual := test.A.Apply(diff)
				if !(len(actual) == 0 && len(test.B) == 0) &&
					!reflect.DeepEqual(actual, test.B) {
					t.Error("got", actual, "expected", test.B)
				}
			}
		})
	}
}

func Test_idSliceLCS(t *testing.T) {
	for _, test := range []struct {
		N          string
		A, B       IDSlice
		AI, BI, LN int
	}{
		{"both empty", IDSlice{}, IDSlice{}, 0, 0, 0},
		{"a empty", IDSlice{"a"}, IDSlice{}, 0, 0, 0},
		{"b empty", IDSlice{}, IDSlice{"a"}, 0, 0, 0},
		{"total mismatch", IDSlice{"a", "b"}, IDSlice{"c", "d"}, 0, 0, 0},
		{"match at start", IDSlice{"a", "b"}, IDSlice{"a", "c"}, 0, 0, 1},
		{"match at end", IDSlice{"a", "b"}, IDSlice{"c", "b"}, 1, 1, 1},
		{"match all", IDSlice{"a", "b"}, IDSlice{"a", "b"}, 0, 0, 2},
		{"match multi middle", IDSlice{"0", "a", "b", "1"}, IDSlice{"2", "a", "b", "3"}, 1, 1, 2},
	} {
		t.Run(test.N, func(t *testing.T) {
			ai, bi, ln := idSliceLCS(test.A, test.B)
			if ai != test.AI || bi != test.BI || ln != test.LN {
				t.Error("got", ai, bi, ln, "expected", test.AI, test.BI, test.LN)
			}
		})
	}
}
