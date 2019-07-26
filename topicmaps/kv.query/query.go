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

package query

import (
	"github.com/google/note-maps/kv"
	"github.com/google/note-maps/topicmaps/kv.models"
)

// Store adds some query logic to models.Store.
type Store struct{ models.Store }

func (s *Store) TopicsByName(c *kv.IndexCursor, n int) ([]kv.Entity, error) {
	ns, err := s.EntitiesByNameValue(c, n)
	if err != nil {
		return nil, err
	}
	names, err := s.GetNameSlice(ns)
	if err != nil {
		return nil, err
	}
	ts := make([]kv.Entity, len(names))
	for i := range names {
		ts[i] = kv.Entity(names[i].Topic)
	}
	return ts, nil
}
