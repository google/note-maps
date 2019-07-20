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

// Package kv provides some useful abstractions over local key-value storage.
//
//   go get github.com/google/note-maps/kv/...
//
// The model implemented by kv maps entities, which are like identifiers,
// to component values, which can be any Go type. Entity is an alias for
// uint64, and components are defined by kvschema, a code generator. The code
// generator looks for types that define the Encoder and Decoder interfaces
// from this package and produces strongly typed code for storing and
// retrieving instances of those types as values.
//
// Package kv also supports indexing. If a component value type, in addition to
// implementing Encoder and Decoder, also has one or more index methods, the
// generated code will also support looking up entities or loading entities in
// order according to each index. An index method must: have a name that starts
// with "Index", receive no arguments, and return a slice of a type that also
// implementes Encoder and Decoder.
//
// Examples are included in the "examples" subdirectory.
//
// If `go generate` doesn't produce a kvschema.go file, or the resulting
// kvschema.go file does not include support for all the types you've defined,
// try `kvschema -v` to find out why.
package kv

import (
	"encoding/binary"
	"sort"
)

// Store represents a the functions a key-value store must implement in order
// to be used as a backing store in this package.
//
// It is valid, even recommended, for Store to be implemented by a type that
// represents a transaction, rather than one that represents an open
// connection.
type Store interface {
	// Alloc should never return the same Entity value twice until the space of
	// possible Entity values is exhausted.
	//
	// Alloc cannot be implemented through Get and Set operations on the Store
	// interface itself becuase independent concurrent transactions require
	// mutually unique Entity values, and the Store interface maybe implemented
	// by a transaction type.
	Alloc() (Entity, error)

	// Set stores key and value in the underlying key-value store.
	Set(key, value []byte) error

	// Get finds the value associated with key in the underlying key-value store
	// and passes it to f.
	//
	// If the key does not an exist, this is not an error: Get may or may not
	// pass an empty slice to f.
	//
	// In any case, if f returns an error, then Get must also return an error.
	Get(key []byte, f func([]byte) error) error

	// PrefixIterator returns an iterator over all key-value pairs with keys
	// matching the given prefix.
	//
	// The initial state of the PrefixIterator is not valid: use or Next() or
	// Seek() to move the iterator to a valid key-value pair.
	//
	// The resulting iterator considers all valid keys as relative to the given
	// prefix, so for prefix {1,2} an underlying key {1,2,3,4} will be visible
	// through this iterator as merely {3,4}.
	PrefixIterator(prefix []byte) Iterator
}

// Iterator supports iteration over key-value pairs.
type Iterator interface {
	// Seek moves the iterator to the key-value pair that matches the given key.
	//
	// If there is no such key-value pair, Seek moves to the item with first key
	// after the given key.
	Seek(key []byte)

	// Next moves to the iterator to the next key-value pair.
	Next()

	// Valid returns true if the iterator is at a valid key-value pair.
	Valid() bool

	// Key returns the key of the iterator's current key-value pair.
	//
	// May panic if Valid() returns false.
	Key() []byte

	// Value calls f with the value of the iterator's current key-value pair.
	//
	// May panic if Valid() returns false.
	Value(f func([]byte) error) error

	// Discard releases this iterator, making it invalid for further use.
	Discard()
}

// Encoder is an interface implemented by any type that is to be stored in the
// key or value of a key-value pair.
type Encoder interface {
	Encode() []byte
}

// Decoder is an interface implemented by any type that is to be retrieved from
// the key or value of a key-value pair.
type Decoder interface {
	Decode(src []byte) error
}

// Prefix is a convenience type for constructing keys through concatenation.
type Prefix []byte

// ConcatEntity creates a new Prefix that contains p followed by e.
func (p Prefix) ConcatEntity(e Entity) Prefix {
	b := make([]byte, len(p)+8)
	copy(b, p)
	e.EncodeAt(b[len(p):])
	return b
}

// ConcatEntityComponent creates a new Prefix that contains p followed by e and
// c.
func (p Prefix) ConcatEntityComponent(e Entity, c Component) Prefix {
	b := make([]byte, len(p)+8+2)
	copy(b, p)
	e.EncodeAt(b[len(p):])
	c.EncodeAt(b[len(p)+8:])
	return b
}

// ConcatEntityComponentBytes creates a new Prefix that contains p followed by
// e, c, and bs.
func (p Prefix) ConcatEntityComponentBytes(e Entity, c Component, bs []byte) Prefix {
	b := make([]byte, len(p)+8+2+len(bs))
	copy(b, p)
	e.EncodeAt(b[len(p):])
	c.EncodeAt(b[len(p)+8:])
	copy(b[len(p)+8+2:], bs)
	return b
}

// AppendComponent appends c to p and returns the result.
func (p Prefix) AppendComponent(c Component) Prefix {
	return append(p, c.Encode()...)
}

// Component is a hard-coded and globally unique identifier for a component
// type.
//
// Components are typically hard-coded constants.
type Component uint16

// EncodeAt encodes e into the first two bytes of dst and panics if len(dst) <
// 2.
func (c Component) EncodeAt(dst []byte) {
	binary.BigEndian.PutUint16(dst, uint16(c))
}

// Encode encodes c into a new slice of two bytes.
func (c Component) Encode() []byte {
	var bs [2]byte
	c.EncodeAt(bs[:])
	return bs[:]
}

// Entity is an identifier that can be associated with Go values via
// Components, and
//
// Entities are typically created through Store.Alloc().
type Entity uint64

// EncodeAt encodes e into the first eight bytes of dst and panics if len(dst)
// < 8.
func (e Entity) EncodeAt(dst []byte) {
	binary.BigEndian.PutUint64(dst, uint64(e))
}

// Encode encodes e into a new slice of eight bytes.
func (e Entity) Encode() []byte {
	var bs [8]byte
	e.EncodeAt(bs[:])
	return bs[:]
}

// Decode decodes the first eight bytes of src into e.
func (e *Entity) Decode(src []byte) error {
	*e = Entity(binary.BigEndian.Uint64(src))
	return nil
}

// EntitySlice implements sorting and searching for slices of Entity as well
// as sort order preserving insertion and removal operations.
type EntitySlice []Entity

// Len returns len(es).
//
// Len exists only to implement sort.Interface.
func (es EntitySlice) Len() int { return len(es) }

// Less returns true if and only if es[a] < es[b].
//
// Less exists only to implement sort.Interface.
func (es EntitySlice) Less(a, b int) bool { return es[a] < es[b] }

// Swap swaps the values of es[a] and es[b].
//
// Swap exists only to implement sort.Interface.
func (es EntitySlice) Swap(a, b int) { es[a], es[b] = es[b], es[a] }

// Sort sorts the values of es in ascending order.
func (es EntitySlice) Sort() { sort.Sort(es) }

// Equal returns true if and only if the contents of es match the contents of
// o.
func (es EntitySlice) Equal(o EntitySlice) bool {
	if len(es) != len(o) {
		return false
	}
	for i := range es {
		if es[i] != o[i] {
			return false
		}
	}
	return true
}

// Search returns the index of the first element of es that is greater than or
// equal to e.
//
// In other words, if e is an element of es, then es[es.Search(e)] == e.
// However, if all elements in es are less than e, then es.Search(e) == len(e).
//
// If es is not sorted, the results are undefined.
func (es EntitySlice) Search(e Entity) int {
	return sort.Search(len(es), func(i int) bool { return es[i] >= e })
}

// Insert adds e to es if it is not already included without disrupting the
// sorted ordering of es, and returns true if and only if e was not already
// present.
//
// If es is not already sorted, the results are undefined.
func (es *EntitySlice) Insert(e Entity) bool {
	if i := es.Search(e); i < len(*es) {
		if (*es)[i] == e {
			return false
		}
		*es = append((*es)[:i+1], (*es)[i:]...)
		(*es)[i] = e
	} else {
		*es = append(*es, e)
	}
	return true
}

// Remove removes e from es if it is present without disrupting the sorted
// ordering of es, and returns true if and only if e was there to be removed.
//
// If es is not already sorted, the results are undefined.
func (es *EntitySlice) Remove(e Entity) bool {
	if i := es.Search(e); i < len(*es) && (*es)[i] == e {
		*es = append((*es)[:i], (*es)[i+1:]...)
		return true
	}
	return false
}

// Encode encodes es into a new slice of bytes.
func (es EntitySlice) Encode() []byte {
	bs := make([]byte, 8*len(es))
	for i, e := range es {
		e.EncodeAt(bs[i*8:])
	}
	return bs
}

// Decode decodes src into es.
func (es *EntitySlice) Decode(src []byte) error {
	ln := len(src) / 8
	if len(*es) < ln {
		*es = make([]Entity, ln)
	}
	for i := 0; i < ln; i++ {
		(*es)[i].Decode(src[i*8:])
	}
	return nil
}

// String is an alias for string that implements the Encoder and Decoder
// interfaces.
type String string

// Encode encodes s into a new slice of bytes.
func (s String) Encode() []byte { return []byte(s) }

// Decode decodes src into s.
func (s *String) Decode(src []byte) error {
	*s = String(src)
	return nil
}
