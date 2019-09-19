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

// Package models implements storage and retrieval of topic maps in a local
// key-value store using package kv.
package models

//go:generate kvschema

import (
	"encoding/json"
	"fmt"
	"log"
	"strings"

	"github.com/golang/protobuf/proto"
	"github.com/google/note-maps/kv"
	"github.com/google/note-maps/tmaps/tmdb/models/internal/pb"
)

const (
	TopicMapInfoPrefix     kv.Component = 0x0001
	LiteralPrefix          kv.Component = 0x0002
	IIsPrefix              kv.Component = 0x0003
	SIsPrefix              kv.Component = 0x0004
	SLsPrefix              kv.Component = 0x0005
	TopicNamesPrefix       kv.Component = 0x0006
	TopicOccurrencesPrefix kv.Component = 0x0007
	NamePrefix             kv.Component = 0x0008
	OccurrencePrefix       kv.Component = 0x0009
	ValuePrefix            kv.Component = 0x000A
)

// TopicMapInfo wraps pb.TopicMapInfo to implement kv.Encoder and kv.Decoder
// interfaces.
type TopicMapInfo struct{ pb.TopicMapInfo }

func (tmi *TopicMapInfo) Encode() []byte          { return encodeProto(tmi) }
func (tmi *TopicMapInfo) Decode(src []byte) error { return decodeProto(src, tmi) }

type (
	IIs []string
	SIs []string
	SLs []string
)

func (iis IIs) Encode() []byte { return encodeStringSlice(iis) }
func (sis SIs) Encode() []byte { return encodeStringSlice(sis) }
func (sls SLs) Encode() []byte { return encodeStringSlice(sls) }

func (iis *IIs) Decode(bs []byte) error {
	ss := []string(*iis)
	err := decodeStringSlice(&ss, bs)
	*iis = IIs(ss)
	return err
}
func (sis *SIs) Decode(bs []byte) error {
	ss := []string(*sis)
	err := decodeStringSlice(&ss, bs)
	*sis = SIs(ss)
	return err
}
func (sls *SLs) Decode(bs []byte) error {
	ss := []string(*sls)
	err := decodeStringSlice(&ss, bs)
	*sls = SLs(ss)
	return err
}

func (iis IIs) IndexLiteral() []kv.String { return literalStringSlice(iis) }
func (sis SIs) IndexLiteral() []kv.String { return literalStringSlice(sis) }
func (sls SLs) IndexLiteral() []kv.String { return literalStringSlice(sls) }

// TopicNames holds a slice of all of a topic's names.
//
// TopicNames is not sorted: names are ordered according to user preferences,
// and this is how that ordering is represented in kvmodels.
type TopicNames kv.EntitySlice

func (tns TopicNames) Encode() []byte {
	return kv.EntitySlice(tns).Encode()
}
func (tns *TopicNames) Decode(bs []byte) error {
	es := kv.EntitySlice(*tns)
	err := es.Decode(bs)
	*tns = TopicNames(es)
	return err
}

// TopicOccurrences holds a slice of all of a topic's occurrences.
//
// TopicOccurrences is not sorted: occurrences are ordered according to user
// preferences, and this is how that ordering is represented in kvmodels.
type TopicOccurrences kv.EntitySlice

func (tos TopicOccurrences) Encode() []byte {
	return kv.EntitySlice(tos).Encode()
}
func (tos *TopicOccurrences) Decode(bs []byte) error {
	es := kv.EntitySlice(*tos)
	err := es.Decode(bs)
	*tos = TopicOccurrences(es)
	return err
}

// Name wraps pb.Name to implement kv.Encoder and kv.Decoder interfaces.
type Name struct{ pb.Name }

func (n *Name) Encode() []byte          { return encodeProto(n) }
func (n *Name) Decode(src []byte) error { return decodeProto(src, n) }
func (n *Name) IndexValue() []kv.String { return []kv.String{kv.String(n.GetValue())} }

// Occurrence wraps pb.Names to implement kv.Encoder and kv.Decoder interfaces.
type Occurrence struct{ pb.Occurrence }

func (o *Occurrence) Encode() []byte          { return encodeProto(o) }
func (o *Occurrence) Decode(src []byte) error { return decodeProto(src, o) }
func (o *Occurrence) IndexValue() []kv.String { return []kv.String{kv.String(o.GetValue())} }

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

func encodeProto(src proto.Message) []byte {
	bs, err := proto.Marshal(src)
	if err != nil {
		log.Println(err)
	}
	return bs
}

func decodeProto(src []byte, dst proto.Message) error {
	return proto.Unmarshal(src, dst)
}

func encodeStringSlice(src []string) []byte {
	bs, err := json.Marshal(src)
	if err != nil {
		log.Println(err)
	}
	return bs
}

func decodeStringSlice(dst *[]string, src []byte) error {
	if len(src) == 0 {
		return nil
	}
	return json.Unmarshal(src, dst)
}

func literalStringSlice(src []string) []kv.String {
	dst := make([]kv.String, len(src))
	for i := range src {
		dst[i] = kv.String(src[i])
	}
	return dst
}
