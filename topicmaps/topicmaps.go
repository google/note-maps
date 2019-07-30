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

// Reifiable is a mixin for any item that can be reified by a topic.
type Reifiable struct {
	II []string
}

// Typed is a mixin for any item has a singular type.
type Typed struct {
	Type TopicRef
}

// Valued is a mixin for any item that has a value.
type Valued struct {
	Value string
}

// TypedValued is a mixin for any item that has a value with a datatype.
type TypedValued struct {
	Valued
	Datatype TopicRef
}

// Name is a a TMDM TopicName.
type Name struct {
	Reifiable
	Typed
	Valued
}

// Occurrence is a a TMDM Occurrence.
type Occurrence struct {
	Reifiable
	Typed
	Valued
}

// Topic is a TMDM Topic.
type Topic struct {
	SelfRefs    []TopicRef
	Names       []*Name
	Occurrences []*Occurrence
}

// TopicRef is a reference to a topic.
type TopicRef struct {
	Type TopicRefType
	IRI  string
}

// TopicRefType is a type of TopicRef: II, SI, or SL.
type TopicRefType int

const (
	// II is a TMDM item identifier.
	II TopicRefType = iota

	// SI is a TMDM subject indicator.
	SI

	// SL is a TMDM subject locator.
	SL
)

// String returns a simple string representation of a TopicRefType.
func (trt TopicRefType) String() string {
	switch trt {
	case II:
		return "II"
	case SI:
		return "SI"
	case SL:
		return "SL"
	default:
		return "(unknown topic ref type)"
	}
}

// Association is a TMDM Association.
type Association struct {
	Reifiable
	Typed
	Roles []*Role
}

// Role is a TMDM AssociationRole.
type Role struct {
	Typed
	Player TopicRef
}

// Merger is a sink for TMDM items.
type Merger interface {
	MergeTopic(t *Topic) error
	MergeAssociation(a *Association) error
}

// TopicMap is a TMDM TopicMap.
type TopicMap struct {
	II           []string
	Topics       []*Topic
	Associations []*Association
}

// MergeTopic merges a topic into a TopicMap.
func (tm *TopicMap) MergeTopic(t *Topic) error {
	tm.Topics = append(tm.Topics, t)
	return nil
}

// MergeAssociation merges an association into a TopicMap, updating the
// TopicMap.
func (tm *TopicMap) MergeAssociation(a *Association) error {
	tm.Associations = append(tm.Associations, a)
	return nil
}
