// Do not modify this file: it is automatically generated

// NOTE: these tests require the following definitions in a nearby _test.go
// file:
//
// const (
//   TestRune0
//   TestRune1
//   TestRune2
//   TestRune3
// )

package runes

import (
	"reflect"
	"testing"
)

func TestStringOp_String(t *testing.T) {
	slice := String{TestRune0, TestRune1}
	for _, test := range []struct {
		O StringOp
		S string
	}{
		{StringOpDelete(3), "delete 3"},
		{StringOpRetain(3), "retain 3"},
		{StringOpInsert(slice), "insert " + slice.String()},
	} {
		if actual := test.O.String(); actual != test.S {
			t.Errorf("got %#v, expected %#v", actual, test.S)
		}
	}
}

func TestString_PrefixMatch(t *testing.T) {
	for _, test := range []struct {
		N    string
		A, B String
		M    int
	}{
		{N: "empty"},
		{
			N: "short A",
			A: String{TestRune0},
			B: String{TestRune0, TestRune1},
			M: 1,
		},
		{
			N: "long A",
			A: String{TestRune0, TestRune1},
			B: String{TestRune0},
			M: 1,
		},
		{
			N: "equal length partial match",
			A: String{TestRune0, TestRune1},
			B: String{TestRune0, TestRune2},
			M: 1,
		},
		{
			N: "equal length full match",
			A: String{TestRune0, TestRune1},
			B: String{TestRune0, TestRune1},
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
	delta := String{TestRune0}.
		Append(TestRune1, TestRune2)
	actual := String{TestRune3}.Apply(delta)
	expect := String{
		TestRune3,
		TestRune1,
		TestRune2,
	}
	if len(actual) != len(expect) || actual.PrefixMatch(expect) != len(actual) {
		t.Error("got", actual, "expected", expect)
	}
}

func TestString_CanApply(t *testing.T) {
	for _, test := range []struct {
		S   String
		D   []StringOp
		Can bool
	}{
		{Can: false, D: []StringOp{StringOpDelete(1)}},
		{Can: false, D: []StringOp{StringOpRetain(1)}},
		{Can: true, D: []StringOp{StringOpInsert{TestRune0}}},
	} {
		if can := test.S.CanApply(test.D); can != test.Can {
			t.Error("got", can, "expected", test.Can, "for", test.S, test.D)
		}
	}
}

func TestString_Append(t *testing.T) {
	delta := String{TestRune0}.
		Append(TestRune1, TestRune2)
	actual := String{TestRune3}.Apply(delta)
	expect := String{
		TestRune3,
		TestRune1,
		TestRune2,
	}
	if len(actual) != len(expect) || actual.PrefixMatch(expect) != len(actual) {
		t.Error("got", actual, "expected", expect)
	}
}

func TestString_DeleteElements(t *testing.T) {
	base := String{TestRune0, TestRune1, TestRune0}
	delta := base.DeleteElements(TestRune0)
	if !base.CanApply(delta) {
		t.Error("delta", delta, "cannot be applied to the slice used to create it",
			base)
	}
	actual := base.Apply(delta)
	expect := String{TestRune1}
	if len(actual) != len(expect) || actual.PrefixMatch(expect) != len(actual) {
		t.Error("got", actual, "expected", expect)
	}
}

func TestString_fluentDelta(t *testing.T) {
	base := String{TestRune0, TestRune1}
	delta := base.
		Delete(0, 1).
		Insert(TestRune2).
		Retain(1).
		Insert(TestRune0)
	if !base.CanApply(delta) {
		t.Error("delta", delta, "cannot be applied to the slice used to create it",
			base)
	}
	actual := base.Apply(delta)
	expect := String{
		TestRune2,
		TestRune1,
		TestRune0,
	}
	if len(actual) != len(expect) || actual.PrefixMatch(expect) != len(actual) {
		t.Error("got", actual, "expected", expect)
	}
}

func TestString_Apply(t *testing.T) {
	for _, test := range []struct {
		In       String
		Ops      []StringOp
		Out      String
		CanApply bool
	}{
		{
			In:       String{TestRune0},
			Ops:      []StringOp{StringOpRetain(1)},
			CanApply: true,
			Out:      String{TestRune0},
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

func TestString_Diff_andApply(t *testing.T) {
	for _, test := range []struct {
		N      string
		A, B   String
		LenOps int
	}{
		{"insert", String{}, String{TestRune0}, 1},
		{"delete", String{TestRune0}, String{}, 1},
		{"retain", String{TestRune0}, String{TestRune0}, 1},
		{"insert, delete", String{TestRune0}, String{TestRune1}, 2},
		{"delete, retain", String{TestRune0, TestRune1, TestRune2}, String{TestRune1, TestRune2}, 2},
		{"retain, delete", String{TestRune0, TestRune1, TestRune2}, String{TestRune0, TestRune1}, 2},
		{"retain, delete, insert, retain", String{TestRune0, TestRune1, TestRune2}, String{TestRune0, TestRune3, TestRune2}, 4},
	} {
		t.Run(test.N, func(t *testing.T) {
			diff := StringDiff(test.A, test.B)
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
		A, B       String
		AI, BI, LN int
	}{
		{"both empty", String{}, String{}, 0, 0, 0},
		{"a empty", String{TestRune0}, String{}, 0, 0, 0},
		{"b empty", String{}, String{TestRune0}, 0, 0, 0},
		{"total mismatch", String{TestRune0, TestRune1}, String{TestRune2, TestRune4}, 0, 0, 0},
		{"match at start", String{TestRune0, TestRune1}, String{TestRune0, TestRune2}, 0, 0, 1},
		{"match at end", String{TestRune0, TestRune1}, String{TestRune2, TestRune1}, 1, 1, 1},
		{"match all", String{TestRune0, TestRune1}, String{TestRune0, TestRune1}, 0, 0, 2},
		{"match multi middle", String{TestRune2, TestRune0, TestRune1, TestRune3}, String{TestRune3, TestRune0, TestRune1, TestRune2}, 1, 1, 2},
	} {
		t.Run(test.N, func(t *testing.T) {
			ai, bi, ln := idSliceLCS(test.A, test.B)
			if ai != test.AI || bi != test.BI || ln != test.LN {
				t.Error("got", ai, bi, ln, "expected", test.AI, test.BI, test.LN)
			}
		})
	}
}

func TestStringDelta_Rebase(t *testing.T) {
	for _, test := range []struct {
		N            string
		A, B, Expect StringDelta
	}{
		{"both empty", nil, nil, nil},
		{"insert1 vs empty", String{}.Insert(0, TestRune1), nil, nil},
		{"retain1 vs empty", String{}.Retain(1), nil, nil},
		{"delete1 vs empty", String{}.Delete(0, 1), nil, nil},
		{"empty vs insert1", nil, String{}.Insert(0, TestRune1), String{}.Insert(0, TestRune1)},
		{"empty vs retain1", nil, String{}.Retain(1), String{}.Retain(1)},
		{"empty vs delete1", nil, String{}.Delete(0, 1), String{}.Delete(0, 1)},
		{
			"insert1 vs insert1",
			String{}.Insert(0, TestRune1),
			String{}.Insert(0, TestRune2),
			String{}.Insert(1, TestRune2),
		},
		{
			"insert1 vs retain1",
			String{}.Insert(0, TestRune1),
			String{}.Retain(1),
			String{}.Retain(2),
		},
		{
			"insert1 vs delete1",
			String{}.Insert(0, TestRune1),
			String{}.Delete(0, 1),
			String{}.Retain(1).Delete(1),
		},
		{
			"retain1 vs insert1",
			String{}.Retain(1),
			String{}.Insert(0, TestRune1),
			String{}.Insert(0, TestRune1),
		},
		{
			"retain1 vs retain1",
			String{}.Retain(1),
			String{}.Retain(1),
			String{}.Retain(1),
		},
		{
			"retain1 vs delete1",
			String{}.Retain(1),
			String{}.Delete(0, 1),
			String{}.Delete(0, 1),
		},
		{
			"delete1 vs insert1",
			String{}.Delete(0, 1),
			String{}.Insert(0, TestRune1),
			String{}.Insert(0, TestRune1),
		},
		{
			"delete1 vs retain1",
			String{}.Delete(0, 1),
			String{}.Retain(1),
			String{}.Retain(0),
		},
		{
			"delete1 vs delete1",
			String{}.Delete(0, 1),
			String{}.Delete(0, 1),
			String{}.Retain(0),
		},
	} {
		t.Run(test.N, func(t *testing.T) {
			actual, err := test.B.Rebase(test.A)
			if err != nil {
				t.Error(err)
			} else if len(actual) == 0 && len(test.Expect) == 0 {
			} else if !reflect.DeepEqual(actual, test.Expect) {
				t.Error("got", actual, "expected", test.Expect)
			}
		})
	}
}
