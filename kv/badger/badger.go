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

// Package badger providers a Badger-backed implementation of kv.Store.
package badger

import (
	"github.com/dgraph-io/badger"
	"github.com/google/note-maps/kv"
)

type DB struct {
	*badger.DB
	seq *badger.Sequence
}

type Options struct {
	badger.Options
}

func DefaultOptions(dir string) Options {
	return Options{badger.DefaultOptions(dir)}
}

func Open(opt Options) (*DB, error) {
	bdb, err := badger.Open(opt.Options)
	if err != nil {
		return nil, err
	}
	db, err := With(bdb)
	if err != nil {
		bdb.Close()
		return nil, err
	}
	return db, err
}

func With(db *badger.DB) (*DB, error) {
	seq, err := db.GetSequence([]byte{0}, 128)
	if err != nil {
		return nil, err
	}
	return &DB{db, seq}, nil
}

func (db *DB) Close() error {
	if db.seq != nil {
		db.seq.Release()
	}
	return db.DB.Close()
}

func (db *DB) NewStore(txn *badger.Txn) kv.Store {
	return NewStore(db.seq, txn)
}

// NewStore creates a new value that implements kv.Store over seq and tx.
func NewStore(seq *badger.Sequence, tx *badger.Txn) kv.Store { return store{seq, tx} }

type store struct {
	seq *badger.Sequence
	tx  *badger.Txn
}

func (s store) Alloc() (kv.Entity, error) {
	u64, err := s.seq.Next()
	return kv.Entity(u64), err
}

func (s store) Set(key, value []byte) error { return s.tx.Set(key, value) }

func (s store) Get(key []byte, f func([]byte) error) error {
	item, err := s.tx.Get(key)
	if err != nil {
		return err
	}
	return item.Value(f)
}

func (s store) PrefixIterator(prefix []byte) kv.Iterator {
	opts := badger.DefaultIteratorOptions
	opts.Prefix = prefix
	return iterator{
		s.tx.NewIterator(opts),
		len(prefix),
	}
}

type iterator struct {
	*badger.Iterator
	lenPrefix int
}

func (i iterator) Key() []byte { return i.Item().Key()[i.lenPrefix:] }

func (i iterator) Value(f func([]byte) error) error { return i.Item().Value(f) }

func (i iterator) Discard() { i.Close() }
