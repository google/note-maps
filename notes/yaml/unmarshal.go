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

type NoteModel struct {
	ID          notes.ID
	ValueString string
	ValueType   *NoteModel
	Contents    []*NoteModel
	Types       []*NoteModel
}

func (x *NoteModel) GetID() notes.ID {
	if x == nil {
		return notes.EmptyID
	}
	return x.ID
}
func (x *NoteModel) GetValue() (string, notes.GraphNote, error) {
	if x == nil {
		return "", notes.EmptyNote(notes.EmptyID), nil
	}
	return x.ValueString, x.ValueType, nil
}
func (x *NoteModel) GetContents() ([]notes.GraphNote, error) {
	if x == nil {
		return nil, nil
	}
	return nmslice(x.Contents)
}
func (x *NoteModel) GetTypes() ([]notes.GraphNote, error) {
	if x == nil {
		return nil, nil
	}
	return nmslice(x.Types)
}

func nmslice(ms []*NoteModel) ([]notes.GraphNote, error) {
	gs := make([]notes.GraphNote, len(ms))
	for i, m := range ms {
		gs[i] = m
	}
	return gs, nil
}

func UnmarshalNote(src []byte, dst *NoteModel) error {
	n := yaml.Node{Kind: yaml.DocumentNode}
	if err := yaml.Unmarshal(src, &n); err != nil {
		return err
	}
	return yamlDocumentToNote(&n, dst)
}

func yamlDocumentToNote(src *yaml.Node, dst *NoteModel) error {
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
		src = src.Content[1]
	}
	return yamlNodeToNote(src, dst)
}

func yamlNodeToNote(src *yaml.Node, dst *NoteModel) error {
	if src.Anchor != "" {
		dst.ID = notes.ID(src.Anchor)
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
						dst.ValueType = &NoteModel{ID: vt}
					}
					dst.ValueString = s.Content[1].Value
				default:
					return fmt.Errorf("unsupported YAML type %v (%#v) for subject value",
						s.Kind, s.Value)
				}
			} else {
				// TODO: use a different id when notes are cached and shared? random id
				// to start?
				var c NoteModel
				if err := yamlNodeToNote(s, &c); err != nil {
					return err
				}
				dst.Contents = append(dst.Contents, &c)
			}
		}
	case yaml.ScalarNode:
		if src.LongTag() != "tag:yaml.org,2002:str" {
			dst.ValueType = &NoteModel{ID: notes.ID(src.ShortTag())}
		}
		dst.ValueString = src.Value
	case yaml.MappingNode:
		if len(src.Content) >= 1 {
			typ := src.Content[0]
			dst.Types = append(dst.Types, &NoteModel{ID: notes.ID(typ.Value)})
		}
		if len(src.Content) >= 2 {
			yamlNodeToNote(src.Content[1], dst)
		}
		for i := 2; i < len(src.Content); i += 2 {
			key, val := src.Content[i], src.Content[i+1]
			c := &NoteModel{Types: []*NoteModel{&NoteModel{ID: notes.ID(key.Value)}}}
			if err := yamlNodeToNote(val, c); err != nil {
				return err
			}
			dst.Contents = append(dst.Contents, c)
		}
	default:
		return fmt.Errorf("unsupported content in note, kind=%#v", src.Kind)
	}
	return nil
}
