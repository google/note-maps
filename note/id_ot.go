// Do not modify this file: it is automatically generated

package note

import "strconv"

func (xs IDSlice) Append(add ...ID) IDSliceDelta {
	return xs.Insert(len(xs), add...)
}

func (xs IDSlice) Retain(r int) IDSliceDelta {
	return IDSliceDelta{}.Retain(r)
}

func (xs IDSlice) Insert(i int, add ...ID) IDSliceDelta {
	return xs.Retain(i).Insert(add...)
}

func (xs IDSlice) Delete(i, num int) IDSliceDelta {
	return IDSliceDelta{IDSliceOpRetain(i), IDSliceOpDelete(num)}
}

func (xs IDSlice) DeleteElements(del ...ID) IDSliceDelta {
	is := make(map[int]bool)
	for _, r := range del {
		for i, x := range xs {
			if x == r {
				is[i] = true
			}
		}
	}
	var delta IDSliceDelta
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
func (xs IDSlice) PrefixMatch(ys []ID) int {
	i := 0
	for ; i < len(xs) && i < len(ys); i++ {
		if xs[i] != ys[i] {
			break
		}
	}
	return i
}

type IDSliceDelta []IDSliceOp

func (x IDSliceDelta) Retain(r int) IDSliceDelta {
	if r == 0 {
		return x
	}
	return append(x, IDSliceOpRetain(r))
}
func (x IDSliceDelta) Insert(add ...ID) IDSliceDelta {
	return append(x, IDSliceOpInsert(add))
}
func (x IDSliceDelta) Delete(d int) IDSliceDelta {
	return append(x, IDSliceOpDelete(d))
}

type IDSliceOp interface {
	// Leaves returns how many elements of a slice of length n would remain
	// to be transformed by additional ops after applying this op. Returns
	// a negative number if and only if this op cannot be coherently
	// applied to a slice of length n.
	Leaves(n int) int
	Apply(IDSlice) (include IDSlice, remainder IDSlice)
	String() string
}

type IDSliceOpInsert []ID
type IDSliceOpRetain int
type IDSliceOpDelete int

func (x IDSliceOpInsert) Leaves(in int) int { return in }
func (x IDSliceOpInsert) Apply(xs IDSlice) (IDSlice, IDSlice) {
	return IDSlice(x), xs
}

func (x IDSliceOpInsert) String() string {
	return "insert " + IDSlice(x).String()
}
func (x IDSliceOpRetain) String() string {
	return "retain " + strconv.Itoa(int(x))
}
func (x IDSliceOpDelete) String() string {
	return "delete " + strconv.Itoa(int(x))
}

func (x IDSliceOpRetain) Leaves(in int) int { return in - int(x) }
func (x IDSliceOpRetain) Apply(xs IDSlice) (IDSlice, IDSlice) {
	return xs[:x], xs[x:]
}

func (x IDSliceOpDelete) Leaves(in int) int { return in - int(x) }
func (x IDSliceOpDelete) Apply(xs IDSlice) (IDSlice, IDSlice) {
	return nil, xs[x:]
}

func (xs IDSlice) CanApply(ops []IDSliceOp) bool {
	ln := len(xs)
	for _, op := range ops {
		if ln = op.Leaves(ln); ln < 0 {
			return false
		}
	}
	return true
}

func (xs IDSlice) Apply(ops []IDSliceOp) IDSlice {
	var head, mid, tail IDSlice
	tail = xs
	for _, op := range ops {
		mid, tail = op.Apply(tail)
		head = append(head, mid...)
	}
	return append(head, tail...)
}

// IDSliceDiff produces a set of operations that can be applied to xs to
// produce a slice that would match slice b.
func IDSliceDiff(a, b []ID) IDSliceDelta {
	var (
		ops                IDSliceDelta
		amid, bmid, midlen = idSliceLCS(IDSlice(a), IDSlice(b))
	)
	if midlen == 0 {
		if len(a) > 0 {
			ops = append(ops, IDSliceOpDelete(len(a)))
		}
		if len(b) > 0 {
			ops = append(ops, IDSliceOpInsert(b))
		}
	} else {
		ops = append(ops, IDSliceDiff(a[:amid], b[:bmid])...)
		ops = append(ops, IDSliceOpRetain(midlen))
		ops = append(ops, IDSliceDiff(a[amid+midlen:], b[bmid+midlen:])...)
	}
	return ops
}

func idSliceLCS(a, b IDSlice) (ai, bi, ln int) {
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
