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

package pbapi

import (
	"os"
	"testing"

	"github.com/google/note-maps/kv/kvtest"
	"github.com/google/note-maps/store/pb"
)

func TestTopicMap(t *testing.T) {
	db := kvtest.NewDB(t)
	defer db.Close()
	g := NewGateway(db)
	response, err := g.Mutate(&pb.MutationRequest{
		CreationRequests: []*pb.CreationRequest{
			{ItemType: pb.ItemType_TopicMapItem},
			{ItemType: pb.ItemType_TopicMapItem},
			{ItemType: pb.ItemType_TopicMapItem},
		},
	})
	if err != nil {
		t.Fatal(err)
	}
	creations := response.CreationResponses
	if len(creations) != 3 {
		t.Errorf("want 3, got %v", len(creations))
	}
	for _, c := range creations {
		switch item := c.Item.Specific.(type) {
		case *pb.Item_TopicMap:
			t.Log(item)
		default:
			t.Fatalf("want topic map, got %T", c.Item)
		}
	}
}

func TestName(t *testing.T) {
	db := kvtest.NewDB(t)
	defer db.Close()
	g := NewGateway(db)
	response, err := g.Mutate(&pb.MutationRequest{
		CreationRequests: []*pb.CreationRequest{
			{ItemType: pb.ItemType_TopicMapItem},
		},
	})
	if err != nil {
		t.Fatal(err)
	}
	kvtest.DumpDB(os.Stderr, db)
	if len(response.CreationResponses) != 1 {
		t.Fatal("")
	}
	topicId := response.CreationResponses[0].Item.Specific.(*pb.Item_TopicMap).TopicMap.Topic.Id
	response, err = g.Mutate(&pb.MutationRequest{
		CreationRequests: []*pb.CreationRequest{
			{TopicMapId: topicId, Parent: topicId, ItemType: pb.ItemType_NameItem},
		},
	})
	kvtest.DumpDB(os.Stderr, db)
	if err != nil {
		t.Fatal(err)
	}
	t.Log(response)
	nameId := response.CreationResponses[0].Id
	mutation := &pb.MutationRequest{
		UpdateValueRequests: []*pb.UpdateValueRequest{
			{
				TopicMapId: topicId,
				Id:         nameId,
				ItemType:   pb.ItemType_NameItem,
				Value:      "Test",
			},
		},
	}
	kvtest.DumpDB(os.Stderr, db)
	t.Log(mutation)
	mutated, err := g.Mutate(mutation)
	kvtest.DumpDB(os.Stderr, db)
	if err != nil {
		t.Fatal(err)
	}
	t.Log(mutated)
	// Alright, the name was created and updated, but can we retrieve everything
	// correctly?
	queryResults, err := g.Query(&pb.QueryRequest{
		LoadRequests: []*pb.LoadRequest{
			{TopicMapId: topicId, Id: topicId, ItemType: pb.ItemType_TopicMapItem},
			{TopicMapId: topicId, Id: topicId, ItemType: pb.ItemType_TopicItem},
			{TopicMapId: topicId, Id: nameId, ItemType: pb.ItemType_NameItem},
		},
	})
	if err != nil {
		t.Error(err)
	}
	t.Log(queryResults)
}
