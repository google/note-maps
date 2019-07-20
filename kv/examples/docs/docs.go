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

// Package docs defines a schema for storing documents in a kv.Store.
//
// This package is an example of using the kv package and its included kvschema
// command line tool to generate a strongly-typed API for storing documents as
// components associated with entities in a key-value store.
package docs

//go:generate kvschema

import (
	"bytes"
	"encoding/gob"
	"io"
	"log"
	"strings"

	"github.com/google/note-maps/kv"
)

const (
	DocumentPrefix kv.ComponentPrefix = 3
	TitlePrefix    kv.ComponentPrefix = 4
)

// Document is a component value type.
type Document struct {
	Title   string
	Content string
}

// Encode implements kv.Encoder for storing documents in a kv.Store.
//
// The presence of Encode and Decode methods tells kvschema to produce the
// DocumentComponent type.
func (d *Document) Encode() []byte {
	var buf bytes.Buffer
	err := gob.NewEncoder(&buf).Encode(d)
	if err != nil {
		log.Println(err)
	}
	return buf.Bytes()
}

// Decode implements kv.Decoder for retrieving documents from a kv.Store.
//
// The presence of Encode and Decode methods tells kvschema to produce the
// DocumentComponent type.
func (d *Document) Decode(src []byte) error {
	err := gob.NewDecoder(bytes.NewBuffer(src)).Decode(d)
	if err == io.EOF {
		err = nil
	}
	return err
}

// IndexTitle provides values that should be mapped back to this document
// through an index.
//
// The presence of a method whose name begins with "Index" and continues with
// "Title" tells kvschema to define a DocumentTitleIndex type.
func (d *Document) IndexTitle() []kv.String {
	return []kv.String{
		kv.String(strings.ToLower(d.Title)),
	}
}
