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
	"encoding/json"
	"fmt"
	"testing"
)

func TestParseString(t *testing.T) {
	for itest, test := range []struct {
		In   string
		Want *QueryExpression
		Err  bool
	}{
		{
			In: `.`,
			Want: &QueryExpression{PathExpression: &PathExpression{
				PostfixedExpression: &PostfixedExpression{
					SimpleContent: &SimpleContent{Anchor: &Anchor{Variable: "."}},
				},
			}},
		}, {
			In: `$var''`,
			Want: &QueryExpression{PathExpression: &PathExpression{
				PostfixedExpression: &PostfixedExpression{
					SimpleContent: &SimpleContent{Anchor: &Anchor{Variable: "$var''"}},
				},
			}},
		}, {
			In: `$v'ar`, Err: true,
		}, {
			In: `false`,
			Want: &QueryExpression{PathExpression: &PathExpression{
				PostfixedExpression: &PostfixedExpression{
					SimpleContent: &SimpleContent{Anchor: &Anchor{
						Constant: &Constant{Atom: &Atom{Keyword: FalseKeyword}},
					}},
				},
			}},
		}, {
			In: `. [ some $_ in $0 satisfies not $2 ]`,
			Want: &QueryExpression{PathExpression: &PathExpression{
				PostfixedExpression: &PostfixedExpression{
					SimpleContent: &SimpleContent{Anchor: &Anchor{
						Variable: ".",
					}},
					Postfix: []*Postfix{{
						FilterPostfix: &BooleanPrimitive{
							ExistsClause: &ExistsClause{
								ExistsQuantifier: &ExistsQuantifier{
									Some: true,
								},
								BindingSet: &BindingSet{VariableAssignments: []*VariableAssignment{
									{"$_", &CompositeContent{
										Content: &Content{
											PathExpression: &PathExpression{
												PostfixedExpression: &PostfixedExpression{
													SimpleContent: &SimpleContent{
														Anchor: &Anchor{Variable: "$0"},
													},
												},
											},
										},
									}},
								}},
								BooleanExpression: &BooleanExpression{
									BooleanPrimitive: &BooleanPrimitive{
										Negated: &BooleanPrimitive{
											ExistsClause: &ExistsClause{
												ExistsContent: &CompositeContent{
													Content: &Content{
														PathExpression: &PathExpression{
															PostfixedExpression: &PostfixedExpression{
																SimpleContent: &SimpleContent{
																	Anchor: &Anchor{Variable: "$2"},
																},
															},
														},
													},
												},
											},
										},
									},
								},
							},
						},
					}},
				},
			}},
		},
	} {
		t.Run(fmt.Sprintf("%#v", test.In), func(t *testing.T) {
			t.Logf("%d %q", itest, test.In)
			var got QueryExpression
			err := ParseString(test.In, &got)
			if err != nil {
				if !test.Err {
					t.Error(itest, err)
				}
				return
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
		})
	}
}
