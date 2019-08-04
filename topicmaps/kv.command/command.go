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

package logic

import (
	"fmt"

	"github.com/google/note-maps/kv"
	"github.com/google/note-maps/topicmaps/kv.models"
)

// Txn adds some command logic to models.Txn.
type Txn struct{ models.Txn }

// CreateTopicMap creates a new topic map in s and returns the Entity.
func (s *Txn) CreateTopicMap() (kv.Entity, error) {
	if s.Partition() != 0 {
		return 0, fmt.Errorf("topic maps can only be created with parent zero")
	}

	// Allocate an entity to identify the new topic map.
	tm, err := s.Alloc()
	if err != nil {
		return 0, err
	}

	// Describe the new topic map by creating metadata for it.
	var info models.TopicMapInfo
	info.TopicMap = uint64(tm)
	return tm, s.SetTopicMapInfo(tm, &info)
}

// CreateTopicWithName creates a new topic including the given name.
func (s *Txn) CreateTopicWithName(name string) (kv.Entity, error) {
	if s.Partition() == 0 {
		return 0, fmt.Errorf("topic names can only be created with a non-zero parent")
	}

	// Allocate an entity to identify the new topic.
	t, err := s.Alloc()
	if err != nil {
		return 0, err
	}

	// Create a new name for the new topic.
	//
	// If this is all that's done, and then the name is deleted and there is no
	// other data that references this topic, then the topic also ceases to
	// exist. This is fine: if there's nothing to say about a topic, then it's
	// really not a topic anymore.
	if _, err = s.CreateTopicName(t, name); err != nil {
		return 0, err
	}

	return t, nil
}

// CreateTopicName creates a new name for topic t.
func (s *Txn) CreateTopicName(t kv.Entity, name string) (kv.Entity, error) {
	if s.Partition() == 0 || t == 0 {
		return 0, fmt.Errorf("topic names can only be created with a non-zero parent")
	}

	// Allocate an entity to identify the new name.
	n, err := s.Alloc()
	if err != nil {
		return 0, err
	}

	// Describe the new name with a models.Name.
	var m models.Name
	m.Topic = uint64(t)
	m.Value = name
	if err := s.SetName(n, &m); err != nil {
		return 0, err
	}

	// Add the new name to the end of the topic's list of names.
	if tns, err := s.GetTopicNamesSlice([]kv.Entity{t}); err != nil {
		return 0, err
	} else {
		tns[0] = append(tns[0], n)
		return n, s.SetTopicNames(t, tns[0])
	}
}

// CreateTopicOccurrence creates a new occurrence of topic t with value v.
func (s *Txn) CreateTopicOccurrence(t kv.Entity, v string) (kv.Entity, error) {
	if s.Partition() == 0 || t == 0 {
		return 0, fmt.Errorf("topic occurrences can only be created with a non-zero parent")
	}

	// Allocate an entity to identify the new occurrence.
	o, err := s.Alloc()
	if err != nil {
		return 0, err
	}

	// Describe the new occurrence with a models.Occurrence.
	var m models.Occurrence
	m.Topic = uint64(t)
	m.Value = v
	if err := s.SetOccurrence(o, &m); err != nil {
		return 0, err
	}

	// Add the new occurrence to the end of the topic's list of occurrences.
	if tos, err := s.GetTopicOccurrencesSlice([]kv.Entity{t}); err != nil {
		return 0, err
	} else {
		tos[0] = append(tos[0], o)
		return o, s.SetTopicOccurrences(t, tos[0])
	}
}
