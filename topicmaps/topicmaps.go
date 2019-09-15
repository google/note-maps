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

// Package topicmaps defines a vocabulary of simple types and common constants
// that related packages can use to share topic maps and topic map items.
package topicmaps

import (
	"github.com/google/note-maps/store/pb"
)

// Merger is a sink for TMDM items.
type Merger interface {
	Merge(t *pb.AnyItem) error
}

// TopicMap is a TMDM TopicMap.
type TopicMap struct {
	II       []string
	Children []*pb.AnyItem
}

// MergeTopic merges any item into a TopicMap.
func (tm *TopicMap) Merge(t *pb.AnyItem) error {
	// This is a simplified and incorrect implementation of Merge. A correct
	// implementation would look for existing items to merge with and check for
	// coherence.
	tm.Children = append(tm.Children, t)
	return nil
}

func IsTopic(item *pb.AnyItem) bool {
	if len(item.Names) > 0 || len(item.NameIds) > 0 ||
		len(item.Occurrences) > 0 || len(item.OccurrenceIds) > 0 {
		return true
	}
	for _, ref := range item.Refs {
		if ref.Type == pb.RefType_SubjectIdentifier || ref.Type == pb.RefType_SubjectLocator {
			return true
		}
	}
	return false
}

func IsAssociation(item *pb.AnyItem) bool {
	if len(item.Roles) > 0 || len(item.RoleIds) > 0 {
		return true
	}
	return false
}
