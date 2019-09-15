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
	"github.com/google/note-maps/topicmaps"
	"github.com/google/note-maps/topicmaps/tmql"
)

type Txn struct {
	models.Txn
}

func NewTxn(ms models.Txn) Txn { return Txn{ms} }

// MergeTopic merges a topic into a TopicMap.
func (tx Txn) MergeTopic(t *topicmaps.Topic) error {
	return fmt.Errorf("not yet implemented")
}

// MergeAssociation merges an association into a TopicMap, updating the
// TopicMap.
func (tx Txn) MergeAssociation(a *topicmaps.Association) error {
	return fmt.Errorf("not yet implemented")
}

// Query returns a TupleSequence representing the results of evaluating
// `query`.
func (tx Txn) Query(query *tmql.QueryExpression) (*TupleSequence, error) {
	return nil, fmt.Errorf("not yet implemented")
}

// Query returns a TupleSequence representing the results of evaluating the
// TMQL query expressed in `query`.
func (tx Txn) QueryString(query string) (*TupleSequence, error) {
	var parsed tmql.QueryExpression
	if err := tmql.ParseString(query, &parsed); err != nil {
		return nil, err
	}
	return tx.Query(&parsed)
}

// TupleSequence is the generic result type for all TMQL queries.
type TupleSequence struct {
	Columns []*TupleSequenceColumn
}

// TupleSequenceColumn is a typed column in a TupleSequnece.
//
// For now, only columns of entities are supported; this may change.
type TupleSequenceColumn struct {
	Entities []kv.Entity
}
