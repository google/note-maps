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

package store

import (
	"fmt"

	"github.com/google/note-maps/kv"
	"github.com/google/note-maps/store/models"
	"github.com/google/note-maps/store/pb"
	"github.com/google/note-maps/topicmaps/tmql"
)

type TopicMapNotSpecifiedError struct{}

func (e TopicMapNotSpecifiedError) Error() string {
	return "topic map not specified"
}

type Txn struct {
	models.Txn
}

func NewTxn(ms models.Txn) Txn { return Txn{ms} }

// Merge merges any topic map item into the backing store.
func (tx Txn) Merge(t *pb.AnyItem) error {
	if t.TopicMapId != 0 {
		tx.Partition = kv.Entity(t.TopicMapId)
	} else if tx.Partition == 0 {
		return TopicMapNotSpecifiedError{}
	} else {
		t.TopicMapId = uint64(tx.Partition)
	}
	var (
		te  kv.Entity
		err error
	)
	if t.ItemId != 0 {
		te = kv.Entity(t.ItemId)
	} else {
		te, err = tx.Alloc()
		if err != nil {
			return err
		}
		t.ItemId = uint64(te)
	}
	ns := kv.EntitySlice(uint64sToEntities(t.NameIds))
	ns.Sort()
	for _, name := range t.Names {
		if err = tx.Merge(name); err != nil {
			return err
		}
		ns.Insert(kv.Entity(name.ItemId))
	}
	if err := tx.SetTopicNames(te, models.TopicNames(ns)); err != nil {
		return err
	}
	os := kv.EntitySlice(uint64sToEntities(t.OccurrenceIds))
	os.Sort()
	for _, occurrence := range t.Occurrences {
		if err = tx.Merge(occurrence); err != nil {
			return err
		}
		os.Insert(kv.Entity(occurrence.ItemId))
	}
	if err := tx.SetTopicOccurrences(te, models.TopicOccurrences(os)); err != nil {
		return err
	}
	return nil
}

// Query returns a TupleSequence representing the results of evaluating
// `query`.
func (tx Txn) Query(query *tmql.QueryExpression) (*pb.TupleSequence, error) {
	return nil, fmt.Errorf("not yet implemented")
}

// Query returns a TupleSequence representing the results of evaluating the
// TMQL query expressed in `query`.
func (tx Txn) QueryString(query string) (*pb.TupleSequence, error) {
	var parsed tmql.QueryExpression
	if err := tmql.ParseString(query, &parsed); err != nil {
		return nil, err
	}
	return tx.Query(&parsed)
}

func uint64sToEntities(us []uint64) []kv.Entity {
	es := make([]kv.Entity, len(us))
	for i, u := range us {
		es[i] = kv.Entity(u)
	}
	return es
}
