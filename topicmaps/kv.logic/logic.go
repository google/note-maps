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
	"github.com/google/note-maps/topicmaps/kv.models"
)

// Store adds business logic to models.Store.
type Store struct{ models.Store }

// CreateTopicMap creates a new topic map in s and returns a copy of the topic
// map's new metadata.
func (s *Store) CreateTopicMap() (*models.TopicMapInfo, error) {
	entity, err := s.Alloc()
	if err != nil {
		return nil, err
	}
	info := &models.TopicMapInfo{}
	info.TopicMap = uint64(entity)
	return info, s.SetTopicMapInfo(entity, info)
}
