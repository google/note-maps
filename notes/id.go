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

// Package notes provides types and functions for interacting with a note maps
// data storage system.
package notes

import "strconv"

// ID is the type of values that identify notes.
type ID string

type IDSlice []ID

type IDSliceOp interface {
	// Leaves returns how many items would be left in the slice beyond the scope
	// of this op. If it returns a negative number, then calling Apply on a slice
	// of that length may panic.
	Leaves(in int) (out int)
	Apply(IDSlice) (include IDSlice, remainder IDSlice)
}

type IDSliceOpInsert []ID
type IDSliceOpRetain int
type IDSliceOpDelete int

func (x IDSliceOpInsert) Leaves(in int) int { return in }
func (x IDSliceOpInsert) Apply(ids IDSlice) (IDSlice, IDSlice) {
	return IDSlice(x), ids
}

func (x IDSliceOpRetain) String() string {
	return "retain " + strconv.Itoa(int(x))
}
func (x IDSliceOpRetain) Leaves(in int) int { return in - int(x) }
func (x IDSliceOpRetain) Apply(ids IDSlice) (IDSlice, IDSlice) {
	return ids[:x], ids[x:]
}

func (x IDSliceOpDelete) String() string {
	return "delete " + strconv.Itoa(int(x))
}
func (x IDSliceOpDelete) Leaves(in int) int { return in - int(x) }
func (x IDSliceOpDelete) Apply(ids IDSlice) (IDSlice, IDSlice) {
	return nil, ids[x:]
}

type IDSliceDelta []IDSliceOp

func (ids IDSlice) CanApply(ops []IDSliceOp) bool {
	ln := len(ids)
	for _, op := range ops {
		if ln = op.Leaves(ln); ln < 0 {
			return false
		}
	}
	return true
}

func (ids IDSlice) Apply(ops []IDSliceOp) IDSlice {
	var head, mid, tail IDSlice
	tail = ids
	for _, op := range ops {
		mid, tail = op.Apply(tail)
		head = append(head, mid...)
	}
	return append(head, tail...)
}

// Diff produces a set of operations that can be applied to ids to
// produce a slice that would match slice b.
func (ids IDSlice) Diff(b IDSlice) IDSliceDelta {
	var (
		ops                IDSliceDelta
		a                  = ids
		amid, bmid, midlen = idSliceLCS(a, b)
	)
	if midlen == 0 {
		if len(a) > 0 {
			ops = append(ops, IDSliceOpDelete(len(a)))
		}
		if len(b) > 0 {
			ops = append(ops, IDSliceOpInsert(b))
		}
	} else {
		ops = append(ops, a[:amid].Diff(b[:bmid])...)
		ops = append(ops, IDSliceOpRetain(midlen))
		ops = append(ops, a[amid+midlen:].Diff(b[bmid+midlen:])...)
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
