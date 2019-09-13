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

package tmql

import (
	"bytes"
	"encoding/json"
	"testing"
)

func TestParser(t *testing.T) {
	for itest, test := range []struct {
		In   string
		Want Query
		Err  bool
	}{
		{In: "", Want: Query{}},
		// Not much is supported yet, just verify that parsing a non-empty query
		// produces an error:
		{In: ". >> types", Want: Query{
			Path: &PathExpression{
				Postfix: []*Postfix{
					{
						Filter: &BooleanPrimitive{
							Min: 1,
							Max: ^uint(0),
							Bindings: BindingSet{"$_": &ContentInfix{
								L: &PathExpression{
									Simple: &SimpleContent{
										Anchor: &Anchor{
											Variable: "$0",
										},
										Navigation: []*Step{
											{Axis: AxisTypes},
										},
									},
								},
								Op: InfixIntersection,
								R: &PathExpression{
									Simple: &SimpleContent{
										Anchor: &Anchor{
											Variable: "$topic",
										},
									},
								},
							}},
						},
					},
				},
			},
		}},
		{In: ". == $topic", Want: Query{
			Path: &PathExpression{
				Postfix: []*Postfix{
					{
						Filter: &BooleanPrimitive{
							Min: 1,
							Max: ^uint(0),
							Bindings: BindingSet{"$_": &ContentInfix{
								L: &PathExpression{
									Simple: &SimpleContent{
										Anchor: &Anchor{
											Variable: "$0",
										},
										Navigation: []*Step{
											{Axis: AxisTypes},
										},
									},
								},
								Op: InfixIntersection,
								R: &PathExpression{
									Simple: &SimpleContent{
										Anchor: &Anchor{
											Variable: "$topic",
										},
									},
								},
							}},
						},
					},
				},
			},
		}},
	} {
		t.Logf("%d %q", itest, test.In)
		var got Query
		err := Parse(bytes.NewReader([]byte(test.In)), &got)
		if err != nil {
			if !test.Err {
				t.Error(itest, err)
			}
			continue
		}
		gotBytes, err := json.Marshal(got)
		if err != nil {
			t.Fatal(itest, err)
		}
		wantBytes, err := json.Marshal(test.Want)
		if err != nil {
			t.Fatal(itest, err)
		}
		gotStr, wantStr := string(gotBytes), string(wantBytes)
		if gotStr != wantStr {
			t.Errorf("%d\ngot  %s\nwant %s", itest, gotStr, wantStr)
		}
	}
}
