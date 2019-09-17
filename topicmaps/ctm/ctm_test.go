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

package ctm

import (
	"bytes"
	"encoding/json"
	"fmt"
	"testing"

	"github.com/google/note-maps/store/pb"
	tm "github.com/google/note-maps/topicmaps"
)

func TestParser(t *testing.T) {
	for itest, test := range []struct {
		In   string
		Want tm.TopicMap
		Err  bool
	}{
		{In: "", Want: tm.TopicMap{}},
		{In: "# comment", Want: tm.TopicMap{}},
		{In: `%encoding "UTF-8"`, Want: tm.TopicMap{}},
		{In: `%encoding "whatever"`, Err: true},
		{In: `%version 1.0`, Want: tm.TopicMap{}},
		{In: `%version 2.0`, Err: true},
		{
			In:   "%encoding \"UTF-8\"\n%version 1.0\n# Empty with full prolog and comment",
			Want: tm.TopicMap{},
		},
		{
			In: `
					%encoding "UTF-8"
					%version 1.0
					# A topic map with one topic.
					test_id - "Test Name".
					`,
			Want: tm.TopicMap{
				Children: []*pb.AnyItem{
					{
						Refs:  []*pb.Ref{{Type: pb.RefType_ItemIdentifier, Iri: "test_id"}},
						Names: []*pb.AnyItem{{Value: "Test Name"}},
					},
				},
			},
		}, {
			In: `
					%prefix wiki http://en.wikipedia.org/wiki/
					wiki:John_Lennon  # QName used as a subject identifier
					- "John Lennon".
					`,
			Want: tm.TopicMap{
				Children: []*pb.AnyItem{
					{
						Refs: []*pb.Ref{{
							Type: pb.RefType_SubjectIdentifier,
							Iri:  "http://en.wikipedia.org/wiki/John_Lennon",
						}},
						Names: []*pb.AnyItem{{Value: "John Lennon"}},
					},
				},
			},
		}, {
			In: `canada note: "cold"; - "Canada".`,
			Want: tm.TopicMap{
				Children: []*pb.AnyItem{
					{
						Refs: []*pb.Ref{{
							Type: pb.RefType_ItemIdentifier,
							Iri:  "canada",
						}},
						Names: []*pb.AnyItem{{Value: "Canada"}},
						Occurrences: []*pb.AnyItem{{
							TypeRef: &pb.Ref{
								Type: pb.RefType_ItemIdentifier,
								Iri:  "note",
							},
							Value: "cold",
						}},
					},
				},
			},
		}, {
			In: "member_of(group: The_Beatles, member: John_Lennon)",
			Want: tm.TopicMap{
				Children: []*pb.AnyItem{
					{
						TypeRef: &pb.Ref{Type: pb.RefType_ItemIdentifier, Iri: "member_of"},
						Roles: []*pb.AnyItem{
							{
								TypeRef:   &pb.Ref{Type: pb.RefType_ItemIdentifier, Iri: "group"},
								PlayerRef: &pb.Ref{Type: pb.RefType_ItemIdentifier, Iri: "The_Beatles"},
							},
							{
								TypeRef:   &pb.Ref{Type: pb.RefType_ItemIdentifier, Iri: "member"},
								PlayerRef: &pb.Ref{Type: pb.RefType_ItemIdentifier, Iri: "John_Lennon"},
							},
						},
					},
				},
			},
		},
	} {
		t.Run(fmt.Sprintf("test %v %q", itest, test.In), func(t *testing.T) {
			var got tm.TopicMap
			err := Parse(bytes.NewReader([]byte(test.In)), &got)
			if err != nil {
				if !test.Err {
					t.Fatal(itest, err)
				}
				return
			}
			gotBytes, err := json.Marshal(got)
			if err != nil {
				if !test.Err {
					t.Error(itest, "got Parse error", err)
				}
			} else if test.Err {
				t.Error(itest, "got no Parse error, want error")
			}
			wantBytes, err := json.Marshal(test.Want)
			if err != nil {
				t.Error(itest, err)
			}
			gotStr, wantStr := string(gotBytes), string(wantBytes)
			if gotStr != wantStr {
				t.Errorf("%d\ngot  %s\nwant %s", itest, gotStr, wantStr)
			}
		})
	}
}
