// Copyright 2020 Google LLC
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

package yaml

import (
	"strings"
	"testing"

	"github.com/golang/protobuf/proto"
	"github.com/google/note-maps/notes/notespb"
)

func TestMarshalUnmarshal(t *testing.T) {
	for _, test := range []struct {
		title string
		proto *notespb.Info
		yaml  []string
	}{
		//{},
		//{ yaml: "note:\n- name: test", },
		{
			title: "subject with one note",
			proto: &notespb.Info{
				Subject: &notespb.Subject{Id: 10},
				Contents: []*notespb.Info_Content{
					{
						Content: &notespb.Info_Content_Property{
							Property: &notespb.Subject{Id: 11},
						},
					},
				},
			},
			yaml: []string{
				"note: &10",
				"    - !id 11",
			},
		}, {
			title: "subject with a value",
			proto: &notespb.Info{
				Subject: &notespb.Subject{Id: 10},
				Value:   &notespb.Info_Value{Lexical: "test value"},
			},
			yaml: []string{
				"note: &10",
				"    - is: test value",
			},
		},
	} {
		t.Run(test.title, func(t *testing.T) {
			expectedYaml := strings.Join(test.yaml, "\n") + "\n"
			var actualProto notespb.Info
			err := UnmarshalNote([]byte(expectedYaml), &actualProto)
			if err != nil {
				t.Error(err)
			} else if !proto.Equal(&actualProto, test.proto) {
				t.Errorf(
					"expected proto: %v actual proto: %v",
					test.proto,
					&actualProto)
			}
			actualYamlBytes, err := MarshalNote(test.proto)
			if err != nil {
				t.Error(err)
			} else if string(actualYamlBytes) != expectedYaml {
				t.Errorf(
					"expected yaml: %#v actual yaml: %#v",
					expectedYaml,
					string(actualYamlBytes))
			}
		})
	}
}
