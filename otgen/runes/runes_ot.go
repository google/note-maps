// Do not modify this file: it is automatically generated

package runes

import "strconv"

func (xs String) Append(add ...rune) StringDelta {
	return xs.Insert(len(xs), add...)
}

func (xs String) Retain(r int) StringDelta {
	return StringDelta{}.Retain(r)
}

func (xs String) Insert(i int, add ...rune) StringDelta {
	return xs.Retain(i).Insert(add...)
}

func (xs String) Delete(i, num int) StringDelta {
	return StringDelta{StringOpRetain(i), StringOpDelete(num)}
}

func (xs String) DeleteElements(del ...rune) StringDelta {
	is := make(map[int]bool)
	for _, r := range del {
		for i, x := range xs {
			if x == r {
				is[i] = true
			}
		}
	}
	var delta StringDelta
	from := 0
	deleting := false
	for i := range xs {
		if deleting {
			if !is[i] {
				delta = delta.Delete(i - from)
				deleting = false
				from = i
			}
		} else {
			if is[i] {
				delta = delta.Retain(i - from)
				deleting = true
				from = i
			}
		}
	}
	if deleting {
		delta = delta.Delete(len(xs) - from)
	}
	return delta
}

// PrefixMatch returns the number of elements at the beginning of xs that match the
// elements at the beginning of ys.
func (xs String) PrefixMatch(ys []rune) int {
	i := 0
	for ; i < len(xs) && i < len(ys); i++ {
		if xs[i] != ys[i] {
			break
		}
	}
	return i
}

type StringDelta []StringOp

func (x StringDelta) Retain(r int) StringDelta {
	if r == 0 {
		return x
	}
	return append(x, StringOpRetain(r))
}
func (x StringDelta) Insert(add ...rune) StringDelta {
	return append(x, StringOpInsert(add))
}
func (x StringDelta) Delete(d int) StringDelta {
	return append(x, StringOpDelete(d))
}

type StringOp interface {
	// Leaves returns how many elements of a slice of length n would remain
	// to be transformed by additional ops after applying this op. Returns
	// a negative number if and only if this op cannot be coherently
	// applied to a slice of length n.
	Leaves(n int) int
	Apply(String) (include String, remainder String)
	String() string
}

type StringOpInsert []rune
type StringOpRetain int
type StringOpDelete int

func (x StringOpInsert) Leaves(in int) int { return in }
func (x StringOpInsert) Apply(xs String) (String, String) {
	return String(x), xs
}

func (x StringOpInsert) String() string {
	return "insert " + String(x).String()
}
func (x StringOpRetain) String() string {
	return "retain " + strconv.Itoa(int(x))
}
func (x StringOpDelete) String() string {
	return "delete " + strconv.Itoa(int(x))
}

func (x StringOpRetain) Leaves(in int) int { return in - int(x) }
func (x StringOpRetain) Apply(xs String) (String, String) {
	return xs[:x], xs[x:]
}

func (x StringOpDelete) Leaves(in int) int { return in - int(x) }
func (x StringOpDelete) Apply(xs String) (String, String) {
	return nil, xs[x:]
}

func (xs String) CanApply(ops []StringOp) bool {
	ln := len(xs)
	for _, op := range ops {
		if ln = op.Leaves(ln); ln < 0 {
			return false
		}
	}
	return true
}

func (xs String) Apply(ops []StringOp) String {
	var head, mid, tail String
	tail = xs
	for _, op := range ops {
		mid, tail = op.Apply(tail)
		head = append(head, mid...)
	}
	return append(head, tail...)
}

// StringDiff produces a set of operations that can be applied to xs to
// produce a slice that would match slice b.
func StringDiff(a, b []rune) StringDelta {
	var (
		ops                StringDelta
		amid, bmid, midlen = idSliceLCS(String(a), String(b))
	)
	if midlen == 0 {
		if len(a) > 0 {
			ops = append(ops, StringOpDelete(len(a)))
		}
		if len(b) > 0 {
			ops = append(ops, StringOpInsert(b))
		}
	} else {
		ops = append(ops, StringDiff(a[:amid], b[:bmid])...)
		ops = append(ops, StringOpRetain(midlen))
		ops = append(ops, StringDiff(a[amid+midlen:], b[bmid+midlen:])...)
	}
	return ops
}

func idSliceLCS(a, b String) (ai, bi, ln int) {
	ls := make([]int, len(a)*len(b))
	max := 0
	a0, b0 := 0, 0
	for ai, aa := range a {
		for bi, bb := range b {
			if aa == bb {
				li := ai*len(b) + bi
				if ai == 0 || bi == 0 {
					ls[li] = 1
				} else {
					ls[li] = ls[(ai-1)*len(b)+bi-1] + 1
				}
				if ls[li] > max {
					max = ls[li]
					a0, b0 = ai+1-max, bi+1-max
				}
			}
		}
	}
	return a0, b0, max
}
