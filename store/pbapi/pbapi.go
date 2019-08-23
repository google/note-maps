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
	"time"

	"github.com/google/note-maps/kv"
	"github.com/google/note-maps/store/models"
	"github.com/google/note-maps/store/pb"
)

type Gateway struct {
	db kv.DB
}

func NewGateway(db kv.DB) *Gateway { return &Gateway{db} }

func (g Gateway) Query(q *pb.QueryRequest) (*pb.QueryResponse, error) {
	if err := isWellFormedQueryRequest(q); err != nil {
		return nil, err
	}
	txn := g.db.NewTxn(false)
	defer txn.Discard()
	ms := models.New(txn)
	var response pb.QueryResponse
	for _, load := range q.LoadRequests {
		var loaded pb.LoadResponse
		switch load.ItemType {
		case pb.ItemType_LibraryItem:
			var l pb.Library
			ms.Partition = 0
			if es, err := ms.AllTopicMapInfoEntities(nil, 0); err != nil {
				return nil, err
			} else {
				l.TopicMapIds = entitiesToUint64s(es)
			}
			loaded.Item = &pb.Item{Specific: &pb.Item_Library{&l}}
		case pb.ItemType_TopicMapItem:
			if load.Id == 0 {
				return nil, fmt.Errorf("cannot load topic map 0")
			}
			tm := pb.TopicMap{Id: load.Id}
			ms.Partition = 0
			if info, err := ms.GetTopicMapInfo(kv.Entity(load.Id)); err != nil {
				return nil, err
			} else {
				tm.InTrash = info.InTrash
			}
			ms.Partition = kv.Entity(tm.Id)
			if topic, err := loadTopic(ms, ms.Partition, maskNames|maskOccurrences); err != nil {
				return nil, err
			} else {
				tm.Topic = topic
			}
			loaded.Item = &pb.Item{Specific: &pb.Item_TopicMap{&tm}}
		case pb.ItemType_TopicItem:
			if load.Id == 0 || load.TopicMapId == 0 {
				return nil, fmt.Errorf("too many zeros in request")
			}
			ms.Partition = kv.Entity(load.TopicMapId)
			if topic, err := loadTopic(ms, kv.Entity(load.Id), maskNames|maskOccurrences); err != nil {
				return nil, err
			} else {
				loaded.Item = &pb.Item{Specific: &pb.Item_Topic{topic}}
			}
		case pb.ItemType_NameItem:
			if load.Id == 0 || load.TopicMapId == 0 {
				return nil, fmt.Errorf("too many zeros in request")
			}
			n := pb.Name{TopicMapId: load.TopicMapId, Id: load.Id}
			ms.Partition = kv.Entity(load.TopicMapId)
			if name, err := ms.GetName(kv.Entity(load.Id)); err != nil {
				return nil, err
			} else {
				n.Value = name.Value
			}
			loaded.Item = &pb.Item{Specific: &pb.Item_Name{&n}}
		case pb.ItemType_OccurrenceItem:
			if load.Id == 0 || load.TopicMapId == 0 {
				return nil, fmt.Errorf("too many zeros in request")
			}
			o := pb.Occurrence{TopicMapId: load.TopicMapId, Id: load.Id}
			ms.Partition = kv.Entity(load.TopicMapId)
			if occurrence, err := ms.GetOccurrence(kv.Entity(load.Id)); err != nil {
				return nil, err
			} else {
				o.Value = occurrence.Value
			}
			loaded.Item = &pb.Item{Specific: &pb.Item_Occurrence{&o}}
		default:
			return nil, fmt.Errorf("unsupported load request type: %v", load.ItemType)
		}
		response.LoadResponses = append(response.LoadResponses, &loaded)
	}
	if err := isWellFormedQueryResponse(&response); err != nil {
		return nil, err
	}
	return &response, nil
}

func (g Gateway) Mutate(m *pb.MutationRequest) (*pb.MutationResponse, error) {
	if err := isWellFormedMutationRequest(m); err != nil {
		return nil, err
	}
	txn := g.db.NewTxn(true)
	defer txn.Discard()
	ms := models.New(txn)
	var response pb.MutationResponse
	for _, deletion := range m.DeletionRequests {
		var deleted pb.DeletionResponse
		deleted.Id = deletion.Id
		deleted.TopicMapId = deletion.TopicMapId
		deleted.ItemType = deletion.ItemType
		switch deletion.ItemType {
		case pb.ItemType_TopicMapItem:
			if deletion.TopicMapId != deletion.Id {
				return nil, fmt.Errorf("mismatch topic map id and id: %v != %v", deletion.TopicMapId, deletion.Id)
			}
			deleteTopicMap(ms, deletion.Id)
		case pb.ItemType_TopicItem:
			// TODO: actually delete
		case pb.ItemType_NameItem:
			// TODO: actually delete
		case pb.ItemType_OccurrenceItem:
			// TODO: actually delete
		default:
			return nil, fmt.Errorf("unsupported deletion item type: %v", deletion.ItemType)
		}
		response.DeletionResponses = append(response.DeletionResponses, &deleted)
	}
	for _, creation := range m.CreationRequests {
		e, err := ms.Alloc()
		if err != nil {
			return nil, err
		}
		created := pb.UpdateResponse{
			TopicMapId: creation.TopicMapId,
			Id:         uint64(e),
		}
		switch creation.ItemType {
		case pb.ItemType_TopicMapItem:
			tm := pb.TopicMap{Id: uint64(e)}
			ms.Partition = 0
			info := &models.TopicMapInfo{}
			info.TopicMap = uint64(e)
			info.ModifiedUnixSeconds = time.Now().Unix()
			if err = ms.SetTopicMapInfo(e, info); err != nil {
				return nil, err
			}
			ms.Partition = e
			if topic, err := loadTopic(ms, e, maskNames|maskOccurrences); err != nil {
				return nil, err
			} else {
				tm.Topic = topic
			}
			created.Item = &pb.Item{Specific: &pb.Item_TopicMap{&tm}}
		case pb.ItemType_TopicItem:
			if creation.TopicMapId == 0 {
				return nil, fmt.Errorf("too many zeros in request")
			}
			t := pb.Topic{Id: uint64(e)}
			if err := ms.SetTopicNames(e, nil); err != nil {
				return nil, err
			} else if err := ms.SetTopicOccurrences(e, nil); err != nil {
				return nil, err
			}
			created.Item = &pb.Item{Specific: &pb.Item_Topic{&t}}
		case pb.ItemType_NameItem:
			if creation.TopicMapId == 0 || creation.Parent == 0 {
				return nil, fmt.Errorf("too many zeros in request")
			}
			n := pb.Name{
				Id:       uint64(e),
				ParentId: uint64(creation.Parent),
			}
			pe := kv.Entity(creation.Parent)
			if pns, err := ms.GetTopicNames(pe); err != nil {
				return nil, err
			} else if err = ms.SetTopicNames(pe, append(pns, e)); err != nil {
				return nil, err
			}
			info := &models.Name{}
			info.Topic = creation.Parent
			if err := ms.SetName(e, info); err != nil {
				return nil, err
			}
			created.Item = &pb.Item{Specific: &pb.Item_Name{&n}}
		case pb.ItemType_OccurrenceItem:
			if creation.TopicMapId == 0 || creation.Parent == 0 {
				return nil, fmt.Errorf("too many zeros in request")
			}
			pe := kv.Entity(creation.Parent)
			o := pb.Occurrence{}
			if pos, err := ms.GetTopicOccurrences(pe); err != nil {
				return nil, err
			} else if err = ms.SetTopicOccurrences(pe, append(pos, e)); err != nil {
				return nil, err
			}
			info := &models.Occurrence{}
			info.Topic = creation.Parent
			if err := ms.SetOccurrence(e, info); err != nil {
				return nil, err
			}
			created.Item = &pb.Item{Specific: &pb.Item_Occurrence{&o}}
		default:
			return nil, fmt.Errorf("unsupported create request type: %v", creation.ItemType)
		}
		response.CreationResponses = append(response.CreationResponses, &created)
	}
	for _, orderUpdate := range m.UpdateOrderRequests {
		if orderUpdate.TopicMapId == 0 || orderUpdate.Id == 0 {
			return nil, fmt.Errorf("too many zeros in request")
		}
		var updated pb.UpdateResponse
		switch orderUpdate.Orderable {
		default:
			// TODO: actually update order
			return nil, fmt.Errorf("unsupported update order orderable: %v", orderUpdate.Orderable)
		}
		response.UpdateOrderResponses = append(response.UpdateOrderResponses, &updated)
	}
	for _, valueUpdate := range m.UpdateValueRequests {
		if valueUpdate.TopicMapId == 0 || valueUpdate.Id == 0 {
			return nil, fmt.Errorf("too many zeros in request")
		}
		updated := pb.UpdateResponse{
			TopicMapId: valueUpdate.TopicMapId,
			Id:         valueUpdate.Id,
		}
		switch valueUpdate.ItemType {
		case pb.ItemType_NameItem:
			n := pb.Name{
				Id: valueUpdate.Id,
			}
			ms.Partition = kv.Entity(valueUpdate.TopicMapId)
			if info, err := ms.GetName(kv.Entity(valueUpdate.Id)); err != nil {
				return nil, err
			} else {
				n.Value = info.Value
				n.ParentId = info.Topic
			}
			updated.Item = &pb.Item{Specific: &pb.Item_Name{&n}}
		case pb.ItemType_OccurrenceItem:
			o := pb.Occurrence{
				Id: valueUpdate.Id,
			}
			ms.Partition = kv.Entity(valueUpdate.TopicMapId)
			if info, err := ms.GetOccurrence(kv.Entity(valueUpdate.Id)); err != nil {
				return nil, err
			} else {
				o.Value = info.Value
				o.ParentId = info.Topic
			}
			updated.Item = &pb.Item{Specific: &pb.Item_Occurrence{&o}}
		default:
			return nil, fmt.Errorf("unsupported update value item type: %v", valueUpdate.ItemType)
		}
		response.UpdateValueResponses = append(response.UpdateValueResponses, &updated)
	}
	if err := isWellFormedMutationResponse(&response); err != nil {
		return nil, err
	}
	return &response, txn.Commit()
}

func deleteTopicMap(ms models.Txn, topicMapId uint64) error {
	if topicMapId == 0 {
		return fmt.Errorf("cannot delete topic map zero")
	}
	entity := kv.Entity(topicMapId)
	_, err := ms.GetTopicMapInfo(entity)
	if err != nil {
		return err
	}
	if err = ms.DeleteTopicMapInfo(entity); err != nil {
		return err
	}
	ms.Partition = entity
	if err = ms.DeletePartition(); err != nil {
		return err
	}
	return nil
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
func loadTopic(ms models.Txn, te kv.Entity, f mask) (*pb.Topic, error) {
	if ms.Partition == 0 {
		return nil, fmt.Errorf("cannot load topics from partition zero")
	}

	topic := pb.Topic{
		Id:         uint64(te),
		TopicMapId: uint64(ms.Partition),
	}

	if nes, err := ms.GetTopicNames(te); err != nil {
		return nil, err
	} else if len(nes) > 0 {
		topic.NameIds = entitiesToUint64s(nes)
		if (f & maskNames) != 0 {
			ns, err := ms.GetNameSlice(nes)
			if err != nil {
				return nil, err
			}
			topic.Names = make([]*pb.Name, 0, len(ns))
			for _, n := range ns {
				var loaded pb.Name
				loaded.Value = n.Value
				topic.Names = append(topic.Names, &loaded)
			}
		}
	}

	if oes, err := ms.GetTopicOccurrences(te); err != nil {
		return nil, err
	} else if len(oes) > 0 {
		topic.OccurrenceIds = entitiesToUint64s(oes)
		if (f & maskOccurrences) != 0 {
			os, err := ms.GetOccurrenceSlice(oes)
			if err != nil {
				return nil, err
			}
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

func entitiesToUint64s(es []kv.Entity) []uint64 {
	u64s := make([]uint64, len(es))
	for i, src := range es {
		u64s[i] = uint64(src)
	}
	return u64s
}

func isWellFormedQueryRequest(p *pb.QueryRequest) error {
	for i, query := range p.LoadRequests {
		switch query.ItemType {
		case pb.ItemType_UnspecifiedItem:
			return fmt.Errorf("LoadRequests[%v]: ItemType is unspecified", i)
		case pb.ItemType_LibraryItem:
			if query.TopicMapId != 0 || query.Id != 0 {
				return fmt.Errorf("LoadRequests[%v]: loading library, but TopicMapId and/or Id are non-zero", i)
			}
		case pb.ItemType_TopicMapItem:
			if query.TopicMapId == 0 || query.Id == 0 {
				return fmt.Errorf("LoadRequests[%v]: loading topic map, but TopicMapId and/or Id are zero", i)
			}
			if query.TopicMapId != query.Id {
				return fmt.Errorf("LoadRequests[%v]: loading topic map, but TopicMapId does not match Id: %v != %v", i, query.TopicMapId, query.Id)
			}
		}
	}
	return nil
}

func isWellFormedQueryResponse(p *pb.QueryResponse) error {
	for i, loaded := range p.LoadResponses {
		if loaded.Item == nil || loaded.Item.Specific == nil {
			return fmt.Errorf("LoadResponses[%v]: item is not filled in", i)
		}
		switch item := loaded.Item.Specific.(type) {
		case *pb.Item_TopicMap:
			if item.TopicMap.Id == 0 || item.TopicMap.Topic == nil || item.TopicMap.Topic.Id == 0 {
				return fmt.Errorf("LoadResponses[%v]: loaded topic map, but Id and/or Topic.Id is zero", i)
			}
		case *pb.Item_Topic:
			if item.Topic.Id == 0 {
				return fmt.Errorf("LoadResponses[%v]: loaded topic, but Id is zero", i)
			}
		case *pb.Item_Name:
			if item.Name.Id == 0 {
				return fmt.Errorf("LoadResponses[%v]: loaded name, but Id is zero", i)
			}
			if item.Name.ParentId == 0 {
				return fmt.Errorf("LoadResponses[%v]: loaded name, but ParentId is zero", i)
			}
		case *pb.Item_Occurrence:
			if item.Occurrence.Id == 0 {
				return fmt.Errorf("LoadResponses[%v]: loaded occurrence, but Id is zero", i)
			}
		}
	}
	return nil
}

func isWellFormedMutationRequest(p *pb.MutationRequest) error {
	return nil
}

func isWellFormedMutationResponse(p *pb.MutationResponse) error {
	return nil
}
