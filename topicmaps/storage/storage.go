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

// Package storage implements storage and retrieval of topic maps in a local
// key-value store using package kv.
package storage

//go:generate kvschema

import (
	"bytes"
	"encoding/gob"
	"fmt"
	"time"

	"github.com/google/note-maps/kv"
)

// To allow complex values may be encoded differently in later versions, a
// single byte prefix is included in serialized values to identify the
// encoding.
const (
	// The only format currently supported.
	GobFormat byte = iota
)

const (
	// TopicMapPrefix is the first byte in keys where the following eight bytes
	// identify a topic map.
	TopicMapInfoPrefix kv.Component = 1
)

// TopicMapInfo holds some metadata about a topic map.
type TopicMapInfo struct {
	// TopicMap is the entity this TopicMapInfo describes.
	TopicMap kv.Entity
	Created  time.Time
}

// Encode encodes tmi into a new byte slice.
func (tmi TopicMapInfo) Encode() []byte {
	var value bytes.Buffer
	value.WriteByte(GobFormat)
	gob.NewEncoder(&value).Encode(&tmi)
	return value.Bytes()
}

// Decode decodes src into tmi.
func (tmi *TopicMapInfo) Decode(src []byte) error {
	if src[0] != GobFormat {
		return UnsupportedFormatError(src[0])
	}
	return gob.NewDecoder(bytes.NewReader(src[1:])).Decode(tmi)
}

// CreateTopicMap creates a new topic map in s and returns a copy of the topic
// map's new metadata.
func (s *Store) CreateTopicMap() (*TopicMapInfo, error) {
	entity, err := s.Alloc()
	if err != nil {
		return nil, err
	}
	info := TopicMapInfo{
		TopicMap: entity,
		Created:  time.Now().Truncate(0),
	}
	return &info, s.SetTopicMapInfo(entity, info)
}

// UnsupportedFormatError indicates that a value was found in the key-value
// backing store with an unsupported format code, perhaps due to data
// corruption.
type UnsupportedFormatError byte

func (e UnsupportedFormatError) Error() string {
	return fmt.Sprintf("unsupported format code 0x%x", byte(e))
}
