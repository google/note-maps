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

// Package storage implements storage and retrieval of topic maps in a mounted
// file system using the Badger key-value database libraries.
package storage

import (
	"bytes"
	"encoding/binary"
	"encoding/gob"
	"fmt"
	"time"

	"github.com/dgraph-io/badger"
)

// Key returns a storage key built from a global single-byte prefix followed by
// a sequence of entities.
func Key(buf []byte, prefix byte, entities ...uint64) []byte {
	length := 1 + 8*len(entities)
	if len(buf) < length {
		buf = make([]byte, 1+8*len(entities))
	}
	buf[0] = prefix
	for i, entity := range entities {
		binary.BigEndian.PutUint64(buf[i*8+1:(i+1)*8+1], entity)
	}
	return buf
}

// To allow complex values may be encoded differently in later versions, a
// single byte prefix is included in serialized values to identify the
// encoding.
const (
	// The only format currently supported.
	GobFormat byte = iota
)

const (
	// MetaPrefix is the first byte in keys for metadata about a database.
	//
	// {MetaPrefix, Meta*} : see documentation for Meta* constant.
	MetaPrefix byte = iota

	// TopicMapPrefix is the first byte in keys where the following eight bytes
	// identify a topic map.
	//
	// {TopicMapPrefix, TopicMap} : {GobFormat, TopicMapInfo}
	TopicMapPrefix

	// TopicMapSequence is the badger.Sequence prefix for generating TopicMap
	// values.
	TopicMapSequence
)

// TopicMap is how this package identifies topic maps.
type TopicMap uint64

// Storage is a thin wrapper around a Badger database.
//
// Remember to call Close() on any Storage when finished with it.
type Storage struct {
	db *badger.DB
}

// Open returns a new Storage based on a Badger database stored at dir.
func Open(dir string) (*Storage, error) {
	opts := badger.DefaultOptions
	opts.Dir = dir
	opts.ValueDir = dir
	db, err := badger.Open(opts)
	if err != nil {
		return nil, err
	}
	return &Storage{db: db}, nil
}

// Close closes the underlying Badger database, blocking as necessary to flush
// pending updates to disk.
func (s *Storage) Close() error { return s.db.Close() }

// NewTransaction returns a transaction that can be used to read and, if update
// is true, to write to the underlying store.
func (s *Storage) NewTransaction(update bool) *Transaction {
	return &Transaction{
		s:   s,
		txn: s.db.NewTransaction(update),
	}
}

// Transaction is how all read and write operations are executed.
//
// Remember to call Discard() on any Transaction when finished with it.
type Transaction struct {
	s   *Storage
	txn *badger.Txn
}

// Commit commits changes or returns an error.
//
// Returns nil error if there were no writes.
func (t *Transaction) Commit() error { return t.txn.Commit() }

// Discard is idempotent and must be called for every Transaction when finished
// with it.
func (t *Transaction) Discard() { t.txn.Discard() }

// TopicMapInfo holds some metadata about a topic map.
//
// TODO: Add an identifier for the topicmaps.TopicMap item within the
// associated topic map, whose characteristics and reifying topic can provide
// much more information.
type TopicMapInfo struct {
	TopicMap TopicMap
	Created  time.Time
}

// CreateTopicMap creates a new topic map in transaction t and returns a copy
// of the topic map's new metadata.
func (t *Transaction) CreateTopicMap() (*TopicMapInfo, error) {
	sequence, err := t.s.db.GetSequence(Key(nil, TopicMapSequence), 1)
	if err != nil {
		return nil, err
	}
	entity, err := sequence.Next()
	if err != nil {
		return nil, err
	}
	info := TopicMapInfo{
		TopicMap: TopicMap(entity),
		Created:  time.Now().Truncate(0),
	}
	var value bytes.Buffer
	value.WriteByte(GobFormat)
	gob.NewEncoder(&value).Encode(&info)
	return &info, t.txn.Set(
		Key(nil, TopicMapPrefix, uint64(info.TopicMap)),
		value.Bytes())
}

// TopicMaps returns a TopicMapsQuery that can be used to find topic maps.
//
// TODO: Convert this API to accept a TopicMapsQuery value as a parameter and
// return a TopicMapsCursor isntead, so that TopicMapsQuery values can be
// constructed without access to a transaction. For example, a TopicMapsQuery
// could some day be decoded from a human-written string.
func (t *Transaction) TopicMaps() *TopicMapsQuery {
	return &TopicMapsQuery{t: t}
}

// TopicMapsQuery describes how to fetch topic maps and then creates a cursor
// to do so.
type TopicMapsQuery struct {
	t *Transaction
}

// Cursor creates and returns a TopicMapsCursor that will iterate over topic
// maps as specified by q.
func (q *TopicMapsQuery) Cursor() *TopicMapsCursor {
	return &TopicMapsCursor{
		iter: q.t.txn.NewIterator(badger.DefaultIteratorOptions),
	}
}

// TopicMapsCursor supports iterating over a set of topic maps.
//
// Remember to call Discard() on any TopicMapsCursor when finished with it.
type TopicMapsCursor struct {
	iter    *badger.Iterator
	started bool
}

// Next advances the cursor to the next topic map, which is the first topic map
// if it has not been called before, and returns true if and only if a topic
// map is found.
func (c *TopicMapsCursor) Next() bool {
	prefix := Key(nil, TopicMapPrefix)
	if !c.started {
		c.iter.Seek(prefix)
		c.started = true
	} else {
		c.iter.Next()
	}
	return c.iter.ValidForPrefix(prefix)
}

// Info decodes the TopicMapInfo associated with the current topic map.
//
// Panics unless the most recent call to c.Next() returned true.
func (c *TopicMapsCursor) Info() (*TopicMapInfo, error) {
	var info TopicMapInfo
	err := c.iter.Item().Value(func(val []byte) error {
		if val[0] != GobFormat {
			return UnsupportedFormatError(val[0])
		}
		return gob.NewDecoder(bytes.NewReader(val[1:])).Decode(&info)
	})
	return &info, err
}

// Discard must be called when the cursor is no longer needed.
func (c *TopicMapsCursor) Discard() {
	c.iter.Close()
}

// UnsupportedFormatError indicates that a value was found in the key-value
// backing store with an unsupported format code, perhaps due to data
// corruption.
type UnsupportedFormatError byte

func (e UnsupportedFormatError) Error() string {
	return fmt.Sprintf("unsupported format code 0x%x", byte(e))
}
