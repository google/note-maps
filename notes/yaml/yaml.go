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
	if err := noteToYaml(src, &doc); err != nil {
		return nil, err
	}
	return yaml.Marshal(&doc)
}

func UnmarshalNote(src []byte, dst *notes.StageNote) error {
	n := yaml.Node{Kind: yaml.DocumentNode}
	if err := yaml.Unmarshal(src, &n); err != nil {
		return err
	}
	return yamlDocumentToNote(&n, dst)
}

func noteToYaml(src notes.GraphNote, dst *yaml.Node) error {
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
			y := &yaml.Node{
				Kind:   yaml.ScalarNode,
				Value:  vs,
				Anchor: string(s.GetID()),
			}
			ts, err := s.GetTypes()
			if err != nil {
				return err
			}
			if len(ts) > 0 {
				y = &yaml.Node{
					Kind: yaml.MappingNode,
					Content: []*yaml.Node{
						{Kind: yaml.ScalarNode, Value: string(ts[0].GetID())},
						y,
					},
				}
			}
			sequence.Content = append(sequence.Content, y)
		}
	}
	return nil
}

func yamlDocumentToNote(src *yaml.Node, dst *notes.StageNote) error {
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
	return yamlNodeToNote(src, dst)
}

func yamlNodeToNote(src *yaml.Node, dst *notes.StageNote) error {
	if src.Anchor != "" {
		id := notes.ID(src.Anchor)
		if id != notes.EmptyID {
			dst.ID = id
		}
	}
	if dst.ID.Empty() {
		dst.ID = notes.RandomID()
	}
	// A note without an ID might not be usable, but some ops may work. Let's go
	// ahead either way.
	switch src.Kind {
	case yaml.SequenceNode:
		for _, s := range src.Content {
			if s.Kind == yaml.MappingNode && len(s.Content) == 2 &&
				s.Content[0].Kind == yaml.ScalarNode && s.Content[0].Value == "is" {
				// A note expressed as a sequence may set its own value with a sequence
				// item that is a map, mapping "is" to the value of the note.
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
			} else {
				// TODO: use a different id when notes are cached and shared? random id
				// to start?
				content := dst.Note(notes.EmptyID)
				if err := yamlNodeToNote(s, content); err != nil {
					return err
				}
				dst.AddContent(content.GetID())
			}
		}
	case yaml.ScalarNode:
		var id notes.ID
		if src.Anchor != "" {
			id = notes.ID(src.Anchor)
		}
		var vt notes.ID
		if src.LongTag() != "tag:yaml.org,2002:str" {
			vt = notes.ID(src.ShortTag())
		}
		added, err := dst.AddContent(id)
		if err != nil {
			return err
		}
		added.SetValue(src.Value, vt)
	case yaml.MappingNode:
		if len(src.Content) >= 2 && src.Content[1].Kind == yaml.ScalarNode {
			// A note expressed as a map may use its first key-value pair to specify
			// the note type and note value.
			types, val := src.Content[0], src.Content[1]
			// assumption: key.Kind==yaml.ScalarNode
			dst.InsertTypes(0, notes.ID(types.Value))
			yamlNodeToNote(val, dst)
			for i := 2; i < len(src.Content); i += 2 {
				key, val := src.Content[i], src.Content[i+1]
				// assumption: key.Kind==yaml.ScalarNode
				c := dst.Note(notes.EmptyID)
				if err := yamlNodeToNote(val, c); err != nil {
					return err
				}
				dst.AddContent(c.GetID())
				if err := c.InsertTypes(0, notes.ID(key.Value)); err != nil {
					return err
				}
			}
		}
	default:
		return fmt.Errorf("unsupported content in note, kind=%#v", src.Kind)
	}
	return nil
}
