// Do not modify this file: it is automatically generated

// NOTE: these tests require the following definitions in a nearby _test.go
// file:
//
// const (
//   TestID0
//   TestID1
//   TestID2
//   TestID3
// )

package notes

import (
	"reflect"
	"testing"
)

func TestIDSliceOp_String(t *testing.T) {
	slice := IDSlice{TestID0, TestID1}
	for _, test := range []struct {
		O IDSliceOp
		S string
	}{
		{IDSliceOpDelete(3), "delete 3"},
		{IDSliceOpRetain(3), "retain 3"},
		{IDSliceOpInsert(slice), "insert " + slice.String()},
	} {
		if actual := test.O.String(); actual != test.S {
			t.Errorf("got %#v, expected %#v", actual, test.S)
		}
	}
}

func TestIDSlice_PrefixMatch(t *testing.T) {
	for _, test := range []struct {
		N    string
		A, B IDSlice
		M    int
	}{
		{N: "empty"},
		{
			N: "short A",
			A: IDSlice{TestID0},
			B: IDSlice{TestID0, TestID1},
			M: 1,
		},
		{
			N: "long A",
			A: IDSlice{TestID0, TestID1},
			B: IDSlice{TestID0},
			M: 1,
		},
		{
			N: "equal length partial match",
			A: IDSlice{TestID0, TestID1},
			B: IDSlice{TestID0, TestID2},
			M: 1,
		},
		{
			N: "equal length full match",
			A: IDSlice{TestID0, TestID1},
			B: IDSlice{TestID0, TestID1},
			M: 2,
		},
	} {
		t.Run(test.N, func(t *testing.T) {
			actual := test.A.PrefixMatch(test.B)
			if actual != test.M {
				t.Error("got", actual, "expected", test.M)
			}
		})
	}
	delta := IDSlice{TestID0}.
		Append(TestID1, TestID2)
	actual := IDSlice{TestID3}.Apply(delta)
	expect := IDSlice{
		TestID3,
		TestID1,
		TestID2,
	}
	if len(actual) != len(expect) || actual.PrefixMatch(expect) != len(actual) {
		t.Error("got", actual, "expected", expect)
	}
}

func TestIDSlice_CanApply(t *testing.T) {
	for _, test := range []struct {
		S   IDSlice
		D   []IDSliceOp
		Can bool
	}{
		{Can: false, D: []IDSliceOp{IDSliceOpDelete(1)}},
		{Can: false, D: []IDSliceOp{IDSliceOpRetain(1)}},
		{Can: true, D: []IDSliceOp{IDSliceOpInsert{TestID0}}},
	} {
		if can := test.S.CanApply(test.D); can != test.Can {
			t.Error("got", can, "expected", test.Can, "for", test.S, test.D)
		}
	}
}

func TestIDSlice_Append(t *testing.T) {
	delta := IDSlice{TestID0}.
		Append(TestID1, TestID2)
	actual := IDSlice{TestID3}.Apply(delta)
	expect := IDSlice{
		TestID3,
		TestID1,
		TestID2,
	}
	if len(actual) != len(expect) || actual.PrefixMatch(expect) != len(actual) {
		t.Error("got", actual, "expected", expect)
	}
}

func TestIDSlice_DeleteElements(t *testing.T) {
	base := IDSlice{TestID0, TestID1, TestID0}
	delta := base.DeleteElements(TestID0)
	if !base.CanApply(delta) {
		t.Error("delta", delta, "cannot be applied to the slice used to create it",
			base)
	}
	actual := base.Apply(delta)
	expect := IDSlice{TestID1}
	if len(actual) != len(expect) || actual.PrefixMatch(expect) != len(actual) {
		t.Error("got", actual, "expected", expect)
	}
}

func TestIDSlice_fluentDelta(t *testing.T) {
	base := IDSlice{TestID0, TestID1}
	delta := base.
		Delete(0, 1).
		Insert(TestID2).
		Retain(1).
		Insert(TestID0)
	if !base.CanApply(delta) {
		t.Error("delta", delta, "cannot be applied to the slice used to create it",
			base)
	}
	actual := base.Apply(delta)
	expect := IDSlice{
		TestID2,
		TestID1,
		TestID0,
	}
	if len(actual) != len(expect) || actual.PrefixMatch(expect) != len(actual) {
		t.Error("got", actual, "expected", expect)
	}
}

func TestIDSlice_Apply(t *testing.T) {
	for _, test := range []struct {
		In       IDSlice
		Ops      []IDSliceOp
		Out      IDSlice
		CanApply bool
	}{
		{
			In:       IDSlice{TestID0},
			Ops:      []IDSliceOp{IDSliceOpRetain(1)},
			CanApply: true,
			Out:      IDSlice{TestID0},
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
		{"insert", IDSlice{}, IDSlice{TestID0}, 1},
		{"delete", IDSlice{TestID0}, IDSlice{}, 1},
		{"retain", IDSlice{TestID0}, IDSlice{TestID0}, 1},
		{"insert, delete", IDSlice{TestID0}, IDSlice{TestID1}, 2},
		{"delete, retain", IDSlice{TestID0, TestID1, TestID2}, IDSlice{TestID1, TestID2}, 2},
		{"retain, delete", IDSlice{TestID0, TestID1, TestID2}, IDSlice{TestID0, TestID1}, 2},
		{"retain, delete, insert, retain", IDSlice{TestID0, TestID1, TestID2}, IDSlice{TestID0, TestID3, TestID2}, 4},
	} {
		t.Run(test.N, func(t *testing.T) {
			diff := IDSliceDiff(test.A, test.B)
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
		{"a empty", IDSlice{TestID0}, IDSlice{}, 0, 0, 0},
		{"b empty", IDSlice{}, IDSlice{TestID0}, 0, 0, 0},
		{"total mismatch", IDSlice{TestID0, TestID1}, IDSlice{TestID2, TestID4}, 0, 0, 0},
		{"match at start", IDSlice{TestID0, TestID1}, IDSlice{TestID0, TestID2}, 0, 0, 1},
		{"match at end", IDSlice{TestID0, TestID1}, IDSlice{TestID2, TestID1}, 1, 1, 1},
		{"match all", IDSlice{TestID0, TestID1}, IDSlice{TestID0, TestID1}, 0, 0, 2},
		{"match multi middle", IDSlice{TestID2, TestID0, TestID1, TestID3}, IDSlice{TestID3, TestID0, TestID1, TestID2}, 1, 1, 2},
	} {
		t.Run(test.N, func(t *testing.T) {
			ai, bi, ln := idSliceLCS(test.A, test.B)
			if ai != test.AI || bi != test.BI || ln != test.LN {
				t.Error("got", ai, bi, ln, "expected", test.AI, test.BI, test.LN)
			}
		})
	}
}
