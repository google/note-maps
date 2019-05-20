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

type Reifiable struct {
	II []string
}

type Typed struct {
	Type TopicRef
}

type Valued struct {
	Value string
}

type TypedValued struct {
	Valued
	Datatype TopicRef
}

type Name struct {
	Reifiable
	Typed
	Valued
}

type Topic struct {
	SelfRefs []TopicRef
	Names    []*Name
}

type TopicRef struct {
	Type TopicRefType
	IRI  string
}

type TopicRefType int

const (
	II TopicRefType = iota
	SI
	SL
)

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

type Association struct {
	Reifiable
	Typed
	Roles []*Role
}

type Role struct {
	Typed
	Player TopicRef
}

type Merger interface {
	MergeTopic(t *Topic) error
	MergeAssociation(a *Association) error
}

type TopicMap struct {
	II           []string
	Topics       []*Topic
	Associations []*Association
}

func (tm *TopicMap) MergeTopic(t *Topic) error {
	tm.Topics = append(tm.Topics, t)
	return nil
}

func (tm *TopicMap) MergeAssociation(a *Association) error {
	tm.Associations = append(tm.Associations, a)
	return nil
}
