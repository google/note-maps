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
	"github.com/google/note-maps/note"
	"gopkg.in/yaml.v3"
)

func MarshalNote(src note.GraphNote) ([]byte, error) {
	if src == nil {
		return nil, nil
	}
	var dst yaml.Node
	if err := noteToYaml(src, &dst, 0); err != nil {
		return nil, err
	}
	return yaml.Marshal(&dst)
}

type done int

const (
	doneID done = 1 << iota
	doneType0
	doneParent
)

func noteToYaml(src note.GraphNote, dst *yaml.Node, done done) error {
	if dst.Kind == 0 {
		dst.Kind = yaml.DocumentNode
	}
	cs, err := src.GetContents()
	if err != nil {
		return err
	}
	ts, err := src.GetTypes()
	if err != nil {
		return err
	}
	switch dst.Kind {
	case yaml.DocumentNode:
		dst.Content = []*yaml.Node{{Kind: yaml.MappingNode}}
		return noteToYaml(src, dst.Content[0], done)
	case yaml.MappingNode:
		var typ string
		if len(ts) == 0 {
			typ = "note"
		} else {
			typ = ts[0].GetID().String()
		}
		dst.Content = []*yaml.Node{
			{Kind: yaml.ScalarNode, Value: typ},
			{Kind: yaml.SequenceNode},
		}
		return noteToYaml(src, dst.Content[1], done|doneType0)
	case yaml.ScalarNode:
		if len(cs) > 0 ||
			len(ts) > 1 || (len(ts) == 1 && (done&doneType0 == 0)) {
			dst.Kind = yaml.MappingNode
			return noteToYaml(src, dst, done)
		}
		vs, vt, err := src.GetValue()
		if err != nil {
			return err
		}
		dst.Value = vs
		dst.Tag = vt.GetID().String()
		dst.Anchor = src.GetID().String()
		return nil
	case yaml.SequenceNode:
		cs, err := src.GetContents()
		if err != nil {
			return err
		}
		ts, err := src.GetTypes()
		if err != nil {
			return err
		}
		if len(cs) == 0 && (len(ts) == 0 || (len(ts) == 1 && (done&doneType0 == doneType0))) && (done&doneParent == doneParent) {
			dst.Kind = yaml.ScalarNode
			return noteToYaml(src, dst, done)
		}
		dst.Anchor = src.GetID().String()
		if vs, vt, err := src.GetValue(); err != nil {
			return err
		} else if vs != "" {
			dst.Content = append(dst.Content, &yaml.Node{
				Kind: yaml.MappingNode,
				Content: []*yaml.Node{
					{Kind: yaml.ScalarNode, Value: "is"},
					{Kind: yaml.ScalarNode, Value: vs, Tag: string(vt.GetID())},
				},
			})
		}
		if ss, err := src.GetContents(); err != nil {
			return err
		} else {
			for _, s := range ss {
				d := yaml.Node{Kind: yaml.ScalarNode}
				if err := noteToYaml(s, &d, doneParent); err != nil {
					return err
				}
				dst.Content = append(dst.Content, &d)
			}
		}
		return nil
	default:
		dst.Kind = yaml.MappingNode
		return noteToYaml(src, dst, done)
	}
}
