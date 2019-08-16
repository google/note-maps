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

// Package badger providers a Badger-backed implementation of kv.Txn.
package badger

import (
	"fmt"

	"github.com/dgraph-io/badger"
	"github.com/google/note-maps/kv"
)

var (
	entitySequenceKey = []byte{0}
)

// DB holds some kv-specific state in addition to mixing in a badger.DB.
type DB struct {
	*badger.DB
	seq *badger.Sequence
}

// DefaultOptions returns a recommended default Options value for a database
// rooted at dir.
func DefaultOptions(dir string) badger.Options {
	return badger.DefaultOptions(dir)
}

// Open creates a new DB with the given options.
func Open(opt badger.Options) (*DB, error) {
	bdb, err := badger.Open(opt)
	if err != nil {
		return nil, err
	}

	seq, err := bdb.GetSequence(entitySequenceKey, 128)
	if err != nil {
		bdb.Close()
		return nil, err
	}

	return &DB{bdb, seq}, nil
}

// Close releases unallocated Entity values and closes the database.
func (db *DB) Close() error {
	if db == nil {
		return nil
	}
	if db.seq != nil {
		db.seq.Release()
	}
	return db.DB.Close()
}

// NewTxn creates a new kv.Txn.
func (db *DB) NewTxn(update bool) kv.TxnCommitDiscarder {
	btxn := db.DB.NewTransaction(update)
	return NewTxn(db.seq, btxn)
}

// NewTxn creates a new kv.Txn that uses seq to allocate new Entity values,
// and tx for read and write operations.
//
// NewTxn is a lower-level alternative to creating a kv.Txn through
// DB.NewTxn. Applications that manage their own badger.DB, or that want to
// do additional work on a given badger.Txn before it is committed, can use
// NewTxn to preserve those abilities.
func NewTxn(seq *badger.Sequence, tx *badger.Txn) kv.TxnCommitDiscarder {
	return txn{seq, tx}
}

type txn struct {
	seq *badger.Sequence
	tx  *badger.Txn
}

func (s txn) Alloc() (kv.Entity, error) {
	u64, err := s.seq.Next()
	if u64 == 0 {
		u64, err = s.seq.Next()
		if u64 == 0 {
			return 0, fmt.Errorf("Alloc returned zero twice in a row")
		}
	}
	return kv.Entity(u64), err
}

func (s txn) Set(key, value []byte) error { return s.tx.Set(key, value) }

func (s txn) Get(key []byte, f func([]byte) error) error {
	item, err := s.tx.Get(key)
	if err == badger.ErrKeyNotFound {
		return f(nil)
	} else if err != nil {
		return err
	} else {
		return item.Value(f)
	}
}

func (s txn) PrefixIterator(prefix []byte) kv.Iterator {
	opts := badger.DefaultIteratorOptions
	opts.Prefix = prefix
	return iterator{
		s.tx.NewIterator(opts),
		prefix,
	}
}

func (s txn) Commit() error {
	return s.tx.Commit()
}

func (s txn) Discard() {
	s.tx.Discard()
}

type iterator struct {
	*badger.Iterator
	prefix []byte
}

func (i iterator) Seek(key []byte) { i.Iterator.Seek(append(i.prefix, key...)) }

func (i iterator) Key() []byte { return i.Item().Key()[len(i.prefix):] }

func (i iterator) Value(f func([]byte) error) error { return i.Item().Value(f) }

func (i iterator) Discard() { i.Close() }
