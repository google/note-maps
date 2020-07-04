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

// Package notes provides types and functions for interacting with a note maps
// data storage system.
package notes

type simpleNote struct {
	valuestring string
	valuetype   uint64
	contents    []uint64
}

func simplify(src Note) (dst simpleNote, err error) {
	var dt Note
	dst.valuestring, dt, err = src.GetValue()
	if err != nil {
		return
	}
	if dt != nil {
		dst.valuetype = dt.GetId()
	}
	var cs []Note
	cs, err = src.GetContents()
	if err != nil {
		return
	}
	dst.contents = make([]uint64, len(cs))
	for i, c := range cs {
		if c != nil {
			dst.contents[i] = c.GetId()
		}
	}
	return
}
func Equal(a, b Note) (bool, error) {
	if a == b {
		return true, nil
	}
	if a.GetId() != b.GetId() {
		return false, nil
	}
	sa, err := simplify(a)
	if err != nil {
		return false, err
	}
	sb, err := simplify(b)
	if err != nil {
		return false, err
	}
	if sa.valuestring != sb.valuestring ||
		sa.valuetype != sb.valuetype ||
		len(sa.contents) != len(sb.contents) {
		return false, nil
	}
	for i, ac := range sa.contents {
		if sb.contents[i] != ac {
			return false, nil
		}
	}
	return true, nil
}
func DebugDiff(a, b Note) (string, interface{}, interface{}, error) {
	if a == b {
		return "", nil, nil, nil
	}
	if a.GetId() != b.GetId() {
		return "id", a.GetId(), b.GetId(), nil
	}
	sa, err := simplify(a)
	if err != nil {
		return "", nil, nil, err
	}
	sb, err := simplify(b)
	if err != nil {
		return "", nil, nil, err
	}
	if sa.valuestring != sb.valuestring {
		return "value.lexical", sa.valuestring, sb.valuestring, nil
	}
	if sa.valuetype != sb.valuetype {
		return "value.type", sa.valuetype, sb.valuetype, nil
	}
	if len(sa.contents) != len(sb.contents) {
		return "len(contents)", sa.contents, sb.contents, nil
	}
	for i, ac := range sa.contents {
		if sb.contents[i] != ac {
			return "contents", sa.contents, sb.contents, nil
		}
	}
	return "", nil, nil, nil
}
