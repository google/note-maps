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
	return xs.Retain(i).Delete(num)
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
func (x IDSliceDelta) Rebase(base IDSliceDelta) (IDSliceDelta, error) {
	var res IDSliceDelta
	xi, bi := 0, 0
	var r, xop, bop IDSliceOp
	for {
		if xop == nil {
			if xi >= len(x) {
				break
			}
			xop = x[xi]
			xi++
		}
		if bop == nil {
			if bi >= len(base) {
				break
			}
			bop = base[bi]
			bi++
		}
		r, xop, bop = xop.Rebase(bop)
		if r != nil {
			res = append(res, r)
		}
	}
	if xop != nil {
		res = append(res, xop)
	}
	res = append(res, x[xi:]...)
	var cres IDSliceDelta
	for _, r := range res {
		if len(cres) == 0 {
			if r.Len() > 0 {
				cres = append(cres, r)
			}
		} else {
			c, ok := cres[len(cres)-1].Compact(r)
			if ok {
				cres[len(cres)-1] = c
			} else if !ok && r.Len() > 0 {
				cres = append(cres, r)
			}
		}
	}
	return cres, nil
}

type IDSliceOp interface {
	// Leaves returns how many elements of a slice of length n would remain
	// to be transformed by additional ops after applying this op. Returns
	// a negative number if and only if this op cannot be coherently
	// applied to a slice of length n.
	Leaves(n int) int
	// Len returns the number of elements inserted, retained, or deleted by
	// this op.
	Len() int
	// Skip returns an equivalent op that assumes its intent is already carried
	// out for the first n elements. May panic if n > Len().
	Skip(n int) IDSliceOp
	// Rebase transforms op into a rebased op r (or nil), a subsequent op for
	// rebasing xn (or nil), and a subsequent base bn (or nil).
	Rebase(base IDSliceOp) (r IDSliceOp, xn IDSliceOp, bn IDSliceOp)
	// Compact expands this op to include o if possible, returning true if
	// successful.
	Compact(o IDSliceOp) (IDSliceOp, bool)
	Apply(IDSlice) (include IDSlice, remainder IDSlice)
	String() string
}

type IDSliceOpInsert []ID
type IDSliceOpRetain int
type IDSliceOpDelete int

func (x IDSliceOpInsert) Leaves(in int) int { return in }
func (x IDSliceOpInsert) Len() int          { return len(x) }

func (x IDSliceOpInsert) Skip(n int) IDSliceOp { return x[n:] }
func (x IDSliceOpInsert) Rebase(base IDSliceOp) (IDSliceOp, IDSliceOp, IDSliceOp) {
	switch bo := base.(type) {
	case IDSliceOpInsert:
		return IDSliceOpRetain(bo.Len()), x, nil
	case IDSliceOpRetain:
		return x, nil, bo
	case IDSliceOpDelete:
		return x, nil, bo
	}
	panic("unknown base type")
}
func (x IDSliceOpInsert) Compact(op IDSliceOp) (IDSliceOp, bool) {
	if o, ok := op.(IDSliceOpInsert); ok {
		return append(x, o...), true
	}
	return x, false
}
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
func (x IDSliceOpRetain) Len() int          { return int(x) }

func (x IDSliceOpRetain) Skip(n int) IDSliceOp { return x - IDSliceOpRetain(n) }
func (x IDSliceOpRetain) Rebase(base IDSliceOp) (IDSliceOp, IDSliceOp, IDSliceOp) {
	switch bo := base.(type) {
	case IDSliceOpInsert:
		// Retain what has been inserted
		return x + IDSliceOpRetain(len(bo)), nil, nil
	case IDSliceOpRetain:
		// Retain the matching prefix
		switch {
		case x < bo:
			return x, nil, bo - x
		case x == bo:
			return x, nil, nil
		case x > bo:
			return bo, x - bo, nil
		}
	case IDSliceOpDelete:
		// Can't retain what has been deleted
		switch {
		case x.Len() < bo.Len():
			// Retention is cancelled by deletion and there is still more to delete.
			return nil, nil, bo - IDSliceOpDelete(x)
		case x.Len() == bo.Len():
			// Retention is cancelled by deletion.
			return nil, nil, nil
		case x.Len() > bo.Len():
			// Retention is partially cancelled by deletion, there is more to retain.
			return nil, x - IDSliceOpRetain(bo), nil
		}
	}
	panic("unknown base type")
}
func (x IDSliceOpRetain) Compact(op IDSliceOp) (IDSliceOp, bool) {
	if o, ok := op.(IDSliceOpRetain); ok {
		return x + o, true
	}
	return x, false
}
func (x IDSliceOpRetain) Apply(xs IDSlice) (IDSlice, IDSlice) {
	return xs[:x], xs[x:]
}

func (x IDSliceOpDelete) Leaves(in int) int { return in - int(x) }
func (x IDSliceOpDelete) Len() int          { return int(x) }

func (x IDSliceOpDelete) Skip(n int) IDSliceOp { return x - IDSliceOpDelete(n) }
func (x IDSliceOpDelete) Rebase(base IDSliceOp) (IDSliceOp, IDSliceOp, IDSliceOp) {
	switch bo := base.(type) {
	case IDSliceOpInsert:
		return IDSliceOpRetain(bo.Len()), x, nil
	case IDSliceOpRetain:
		// Delete the matching prefix
		switch {
		case x.Len() < bo.Len():
			return x, nil, bo - IDSliceOpRetain(x)
		case x.Len() == bo.Len():
			return x, nil, nil
		case x.Len() > bo.Len():
			return IDSliceOpDelete(bo), x.Skip(bo.Len()), nil
		}
	case IDSliceOpDelete:
		switch {
		case x.Len() < bo.Len():
			return nil, nil, bo.Skip(x.Len())
		case x.Len() == bo.Len():
			return nil, nil, nil
		case x.Len() > bo.Len():
			return nil, x - bo, nil
		}
	}
	panic("unknown base type")
}
func (x IDSliceOpDelete) Compact(op IDSliceOp) (IDSliceOp, bool) {
	if o, ok := op.(IDSliceOpDelete); ok {
		return x + o, true
	}
	return x, false
}
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
