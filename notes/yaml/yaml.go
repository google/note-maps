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
	"strconv"

	"github.com/google/note-maps/notes"
	"gopkg.in/yaml.v3"
)

func MarshalNote(src notes.Note) ([]byte, error) {
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

func noteToNode(src notes.Note, dst *yaml.Node) error {
	if src == nil {
		return nil
	}
	// Note contents and more will be marshalled into this YAML sequence.
	var sequence = &yaml.Node{Kind: yaml.SequenceNode}
	// Marshal src identifier.
	id := src.GetId()
	if id != 0 {
		sequence.Anchor = strconv.FormatUint(id, 10)
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
	if vs, _, err := src.GetValue(); err != nil {
		return err
	} else if vs != "" {
		sequence.Content = append(sequence.Content, &yaml.Node{
			Kind: yaml.MappingNode,
			Content: []*yaml.Node{
				{Kind: yaml.ScalarNode, Value: "is"},
				{Kind: yaml.ScalarNode, Value: vs},
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
				Anchor: strconv.FormatUint(s.GetId(), 10),
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
			return fmt.Errorf("expected document to contain a map")
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
		id, err := strconv.ParseUint(src.Anchor, 10, 64)
		if err != nil {
			return err
		}
		if id != 0 {
			dst.Id = id
		}
	}
	for _, s := range src.Content {
		switch s.Kind {
		case yaml.ScalarNode:
			/*
				if s.ShortTag() == "!id" {
					// Unmarshal s.Value into d.Id
					id, err := strconv.ParseUint(s.Value, 10, 64)
					if err != nil {
						return err
					}
					d = dst.Diff.Note(id)
				} else {
			*/
			var id uint64
			if s.Anchor != "" {
				var err error
				id, err = strconv.ParseUint(s.Anchor, 10, 64)
				if err != nil {
					return err
				}
			}
			dst.AddContent(id).SetValue(s.Value, 0)
		case yaml.MappingNode:
			if len(s.Content) == 2 && s.Content[0].Kind == yaml.ScalarNode && s.Content[0].Value == "is" {
				// Unmarshal s.Content[1] into dst.Value
				switch s.Content[1].Kind {
				case yaml.ScalarNode:
					dst.SetValue(s.Content[1].Value, 0)
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
