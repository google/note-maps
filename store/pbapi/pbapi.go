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

// Package pbapi implements an API based on protocol buffer messages.
package pbapi

import (
	"fmt"
	"log"

	"github.com/google/note-maps/kv"
	"github.com/google/note-maps/store/models"
	"github.com/google/note-maps/store/pb"
)

type Gateway struct {
	db kv.DB
}

func NewGateway(db kv.DB) *Gateway { return &Gateway{db} }

func (g Gateway) CreateTopicMap(_ *pb.CreateTopicMapRequest) (*pb.CreateTopicMapResponse, error) {
	txn := g.db.NewTxn(true)
	defer txn.Discard()
	m := models.New(txn)
	m.Partition = 0

	// Allocate an entity to identify the new topic map.
	tm, err := m.Alloc()
	if err != nil {
		return nil, err
	}

	// Describe the new topic map by creating metadata for it.
	var info models.TopicMapInfo
	info.TopicMap = uint64(tm)
	if err = m.SetTopicMapInfo(tm, &info); err != nil {
		return nil, err
	}

	m.Partition = tm
	topic, err := loadTopic(m, tm, maskNames|maskOccurrences)
	if err != nil {
		return nil, err
	}

	if err = txn.Commit(); err != nil {
		return nil, err
	}

	return &pb.CreateTopicMapResponse{
		TopicMap: &pb.TopicMap{
			Id:    uint64(tm),
			Topic: topic,
		},
	}, nil
}

func (g Gateway) GetTopicMaps(_ *pb.GetTopicMapsRequest) (*pb.GetTopicMapsResponse, error) {
	txn := g.db.NewTxn(false)
	defer txn.Discard()
	m := models.New(txn)
	m.Partition = 0

	// Get a slice of entities representing all known topic maps.
	es, err := m.AllTopicMapInfoEntities(nil, 0)
	if err != nil {
		return nil, err
	}
	log.Println("found", len(es), "topic maps")

	var response pb.GetTopicMapsResponse
	for _, e := range es {
		m.Partition = e

		// For each topic map, load the topic that reifies it.
		topic, err := loadTopic(m, e, maskNames|maskOccurrences)
		if err != nil {
			return nil, err
		}

		tm := &pb.TopicMap{
			Id:    uint64(e),
			Topic: topic,
		}
		response.TopicMaps = append(response.TopicMaps, tm)
	}
	return &response, nil
}

// mask describes which fields should be included in a response.
type mask int

const (
	maskRefs mask = 1 << iota
	maskTopicMaps
	maskTopics
	maskNames
	maskOccurrences
)

// loadTopic retrieves f fields of te into a pb.Topic.
func loadTopic(m models.Txn, te kv.Entity, f mask) (*pb.Topic, error) {
	if m.Partition == 0 {
		return nil, fmt.Errorf("cannot load topics from partition zero")
	}

	topic := pb.Topic{
		Id:         uint64(te),
		TopicMapId: uint64(m.Partition),
	}

	if (f & maskNames) != 0 {
		if nes, err := m.GetTopicNames(te); err != nil {
			return nil, err
		} else if ns, err := m.GetNameSlice(nes); err != nil {
			return nil, err
		} else if len(ns) > 0 {
			topic.Names = make([]*pb.Name, 0, len(ns))
			for _, n := range ns {
				var loaded pb.Name
				loaded.Value = n.Value
				topic.Names = append(topic.Names, &loaded)
			}
		}
	}

	if (f & maskOccurrences) != 0 {
		if oes, err := m.GetTopicOccurrences(te); err != nil {
			return nil, err
		} else if os, err := m.GetOccurrenceSlice(oes); err != nil {
			return nil, err
		} else if len(os) > 0 {
			topic.Occurrences = make([]*pb.Occurrence, 0, len(os))
			for _, o := range os {
				var loaded pb.Occurrence
				loaded.Value = o.Value
				topic.Occurrences = append(topic.Occurrences, &loaded)
			}
		}
	}

	return &topic, nil
}
