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
	"testing"

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
				Topics: []*tm.Topic{
					{
						SelfRefs: []tm.TopicRef{
							{
								Type: tm.II,
								IRI:  "test_id",
							},
						},
						Names: []*tm.Name{
							{
								Valued: tm.Valued{"Test Name"},
							},
						},
					},
				},
			},
		},
	} {
		t.Logf("%d %q", itest, test.In)
		var got tm.TopicMap
		err := Parse(bytes.NewReader([]byte(test.In)), &got)
		if err != nil {
			if !test.Err {
				t.Error(itest, err)
			}
			continue
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
	}
}
