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
	"fmt"

	"github.com/google/note-maps/notes"
	"gopkg.in/yaml.v3"
)

func MarshalNote(src notes.GraphNote) ([]byte, error) {
	doc := yaml.Node{Kind: yaml.DocumentNode}
	if err := noteToNode(src, &doc); err != nil {
		return nil, err
	}
	return yaml.Marshal(&doc)
}

func UnmarshalNote(src []byte, dst *notes.StageNote) error {
	n := yaml.Node{Kind: yaml.DocumentNode}
	if err := yaml.Unmarshal(src, &n); err != nil {
		return err
	}
	return yamlToNote(&n, dst)
}

func noteToNode(src notes.GraphNote, dst *yaml.Node) error {
	if src == nil {
		return nil
	}
	// Note contents and more will be marshalled into this YAML sequence.
	var sequence = &yaml.Node{Kind: yaml.SequenceNode}
	// Marshal src identifier.
	id := src.GetID()
	if id != notes.EmptyID {
		sequence.Anchor = string(id)
	}
	// Build outer YAML document structure
	if dst.Kind == yaml.DocumentNode {
		dst.Content = append(dst.Content, &yaml.Node{
			Kind: yaml.MappingNode,
			Content: []*yaml.Node{
				{
					Kind:  yaml.ScalarNode,
					Value: "note",
				},
				sequence,
			},
		})
	} else {
		panic("not supported yet")
	}
	// Marshal subject value. Usually this should be a simple scalar wherever
	// possible, but in the top-level note of a YAML document it should make room
	// for more complexity.
	if vs, vt, err := src.GetValue(); err != nil {
		return err
	} else if vs != "" {
		sequence.Content = append(sequence.Content, &yaml.Node{
			Kind: yaml.MappingNode,
			Content: []*yaml.Node{
				{Kind: yaml.ScalarNode, Value: "is"},
				{Kind: yaml.ScalarNode, Value: vs, Tag: string(vt.GetID())},
			},
		})
	}
	// Marshal src.Contents into sequence, which is dst.Content[1].
	if ss, err := src.GetContents(); err != nil {
		return err
	} else {
		for _, s := range ss {
			vs, _, err := s.GetValue()
			if err != nil {
				return err
			}
			y := yaml.Node{
				Kind:   yaml.ScalarNode,
				Value:  vs,
				Anchor: string(s.GetID()),
			}
			sequence.Content = append(sequence.Content, &y)
		}
	}
	return nil
}

func yamlToNote(src *yaml.Node, dst *notes.StageNote) error {
	// Unwrap the outer YAML document structure.
	if src.Kind == yaml.DocumentNode {
		if len(src.Content) == 0 {
			return nil
		}
		if len(src.Content) > 1 {
			return fmt.Errorf("expected document to contain just one yaml node")
		}
		src = src.Content[0]
		if src.Kind != yaml.MappingNode {
			return fmt.Errorf("expected document to contain a map (%v), found %v in %#v", yaml.MappingNode, src.Kind, src)
		}
		if len(src.Content) != 2 {
			return fmt.Errorf("expected document to contain a map with exactly one key")
		}
		if src.Content[0].Kind != yaml.ScalarNode || src.Content[0].Value != "note" {
			return fmt.Errorf("expected document to contain a map with exactly one key named 'note'")
		}
		src = src.Content[1]
	}
	// Unwrap the subject identifier.
	if src.Anchor != "" {
		id := notes.ID(src.Anchor)
		if id != notes.EmptyID {
			dst.ID = id
		}
	}
	for _, s := range src.Content {
		switch s.Kind {
		case yaml.ScalarNode:
			var id notes.ID
			if s.Anchor != "" {
				id = notes.ID(s.Anchor)
			}
			var vt notes.ID
			if s.LongTag() != "tag:yaml.org,2002:str" {
				vt = notes.ID(s.ShortTag())
			}
			dst.AddContent(id).SetValue(s.Value, vt)
		case yaml.MappingNode:
			if len(s.Content) == 2 && s.Content[0].Kind == yaml.ScalarNode && s.Content[0].Value == "is" {
				// Unmarshal s.Content[1] into dst.Value
				switch s.Content[1].Kind {
				case yaml.ScalarNode:
					var vt notes.ID
					if s.Content[1].LongTag() != "tag:yaml.org,2002:str" {
						vt = notes.ID(s.Content[1].ShortTag())
					}
					dst.SetValue(s.Content[1].Value, vt)
				default:
					return fmt.Errorf("unsupported YAML type %v (%#v) for subject value", s.Kind, s.Value)
				}
				continue //value is not appended to contents
			}
		default:
			return fmt.Errorf("unsupported content in note, kind=%#v", s.Kind)
		}
	}
	return nil
}
