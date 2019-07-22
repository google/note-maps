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

// Package kvschema implements storage and retrieval of topic maps in a local
// key-value store using package kv.
package kvschema

//go:generate kvschema

import (
	"fmt"
	"log"
	"strings"

	"github.com/golang/protobuf/proto"
	"github.com/google/note-maps/kv"
	"github.com/google/note-maps/topicmaps/kvschema/pb"
)

// To allow complex values may be encoded differently in later versions, a
// single byte prefix is included in serialized values to identify the
// encoding.
const (
	// The only format currently supported.
	GobFormat byte = iota
)

const (
	TopicMapInfoPrefix     kv.Component = 1
	IIsPrefix              kv.Component = 3
	SIsPrefix              kv.Component = 4
	SLsPrefix              kv.Component = 5
	TopicNamesPrefix       kv.Component = 6
	TopicOccurrencesPrefix kv.Component = 7
	NamePrefix             kv.Component = 8
	OccurrencePrefix       kv.Component = 9
)

type TopicMapInfo struct{ pb.TopicMapInfo }

func (tmi *TopicMapInfo) Encode() []byte          { return encode(tmi) }
func (tmi *TopicMapInfo) Decode(src []byte) error { return decode(src, tmi) }

type Refs kv.StringSlice

func (r Refs) IndexEntity() []kv.String { return []kv.String(r) }

type (
	ItemIdentifiers   Refs
	SubjectIndicators Refs
	SubjectLocators   Refs
)

// TopicNames holds a slice of all of a topic's names.
//
// TopicNames is not sorted: names are ordered according to user preferences,
// and this is how that ordering is represented in kvschema.
type TopicNames kv.EntitySlice

// TopicOccurrences holds a slice of all of a topic's occurrences.
//
// TopicOccurrences is not sorted: occurrences are ordered according to user
// preferences, and this is how that ordering is represented in kvschema.
type TopicOccurrences kv.EntitySlice

type Name struct{ pb.Name }

func (n *Name) Encode() []byte          { return encode(n) }
func (n *Name) Decode(src []byte) error { return decode(src, n) }

type Occurrence struct{ pb.Occurrence }

func (o *Occurrence) Encode() []byte          { return encode(o) }
func (o *Occurrence) Decode(src []byte) error { return decode(src, o) }

// CreateTopicMap creates a new topic map in s and returns a copy of the topic
// map's new metadata.
func (s *Store) CreateTopicMap() (*TopicMapInfo, error) {
	entity, err := s.Alloc()
	if err != nil {
		return nil, err
	}
	info := &TopicMapInfo{}
	info.TopicMap = uint64(entity)
	return info, s.SetTopicMapInfo(entity, info)
}

// UnsupportedFormatError indicates that a value was found in the key-value
// backing store with an unsupported format code, perhaps due to data
// corruption.
type UnsupportedFormatError byte

func (e UnsupportedFormatError) Error() string {
	return fmt.Sprintf("unsupported format code 0x%x", byte(e))
}

func normalizeURLs(us []string) []kv.String {
	normalized := make([]kv.String, len(us))
	for i := range us {
		normalized[i] = kv.String(strings.ToLower(us[i]))
	}
	return normalized
}

func encode(src proto.Message) []byte {
	bs, err := proto.Marshal(src)
	if err != nil {
		log.Println(err)
	}
	return bs
}

func decode(src []byte, dst proto.Message) error {
	return proto.Unmarshal(src, dst)
}
