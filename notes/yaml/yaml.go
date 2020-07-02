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

	//"github.com/google/note-maps/notes"
	"github.com/google/note-maps/notes/notespb"
	"gopkg.in/yaml.v3"
)

func MarshalNote(src *notespb.Info) ([]byte, error) {
	doc := yaml.Node{Kind: yaml.DocumentNode}
	if err := protoToNode(src, &doc); err != nil {
		return nil, err
	}
	return yaml.Marshal(&doc)
}

func UnmarshalNote(src []byte, dst *notespb.Info) error {
	n := yaml.Node{Kind: yaml.DocumentNode}
	if err := yaml.Unmarshal(src, &n); err != nil {
		return err
	}
	return nodeToProto(&n, dst)
}

func protoToNode(src *notespb.Info, dst *yaml.Node) error {
	if src == nil {
		return nil
	}
	// Note contents and more will be marshalled into this YAML sequence.
	var sequence = &yaml.Node{Kind: yaml.SequenceNode}
	// Marshal src identifier.
	id := src.GetSubject().GetId()
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
	if src.Value != nil && src.Value.Lexical != "" {
		sequence.Content = append(sequence.Content, &yaml.Node{
			Kind: yaml.MappingNode,
			Content: []*yaml.Node{
				{Kind: yaml.ScalarNode, Value: "is"},
				{Kind: yaml.ScalarNode, Value: src.Value.Lexical},
			},
		})
	}
	// Marshal src.Contents into sequence, which is dst.Content[1].
	for _, c := range src.Contents {
		var o yaml.Node
		switch x := c.Content.(type) {
		case *notespb.Info_Content_Property:
			o = yaml.Node{
				Kind:  yaml.ScalarNode,
				Value: strconv.FormatUint(x.Property.GetId(), 10),
				Tag:   "!id",
			}
		default:
			return fmt.Errorf("unsupported content %#v", c.Content)
		}
		sequence.Content = append(sequence.Content, &o)
	}
	return nil
}

func nodeToProto(src *yaml.Node, dst *notespb.Info) error {
	// Unwrap the outer YAML document structure.
	if src.Kind == yaml.DocumentNode {
		if len(src.Content) == 0 {
			return nil
		}
		if len(src.Content) > 1 {
			return fmt.Errorf("expected document to contain just one node")
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
			dst.Subject = &notespb.Subject{Id: id}
		}
	}
	for _, s := range src.Content {
		var d notespb.Info_Content
		switch s.Kind {
		case yaml.ScalarNode:
			if s.Tag == "!id" {
				// Unmarshal s.Value into d.Id
				id, err := strconv.ParseUint(s.Value, 10, 64)
				if err != nil {
					return err
				}
				d.Content = &notespb.Info_Content_Property{
					Property: &notespb.Subject{Id: id},
				}
			} else {
				return fmt.Errorf("unsupported node type: %v", s.Tag)
			}
		case yaml.MappingNode:
			if len(s.Content) == 2 && s.Content[0].Kind == yaml.ScalarNode && s.Content[0].Value == "is" {
				// Unmarshal s.Content[1] into dst.Value
				if dst.Value != nil && dst.Value.Lexical != "" {
					// ...consider turning value into a list in this case?
					return fmt.Errorf("subject cannot have multiple values")
				}
				switch s.Content[1].Kind {
				case yaml.ScalarNode:
					dst.Value = &notespb.Info_Value{Lexical: s.Content[1].Value}
				default:
					return fmt.Errorf("unsupported YAML type %v (%#v) for subject value", s.Kind, s.Value)
				}
				continue //value is not appended to contents
			}
		default:
			return fmt.Errorf("unsupported content in note, kind=%#v", s.Kind)
		}
		dst.Contents = append(dst.Contents, &d)
	}
	return nil
}
