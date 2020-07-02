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

package notes

import (
	"github.com/google/note-maps/notes/notespb"

	"github.com/genjidb/genji"
	"github.com/genjidb/genji/document"
)

type GenjiNoteMap struct {
	db *genji.DB
}

func Open(path string) (*GenjiNoteMap, error) {
	db, err := genji.Open(path)
	if err != nil {
		return nil, err
	}
	db.Exec("CREATE TABLE topics")
	return &GenjiNoteMap{db}, nil
}

func (x *GenjiNoteMap) Close() error {
	return x.db.Close()
}

func (x *GenjiNoteMap) List() (*NoteSet, error) {
	query, err := x.db.Query("SELECT * FROM topics")
	if err != nil {
		return nil, err
	}
	defer query.Close()
	result := NoteSet{
		Infos: make(map[uint64]*notespb.Info),
	}
	return &result, query.Iterate(func(doc document.Document) error {
		var info notespb.Info
		if err := document.StructScan(doc, &info); err != nil {
			return err
		}
		id := info.GetSubject().GetId()
		result.Infos[id] = &info
		//if info.GetValue().GetLexical() != "" || len(info.GetContents()) > 0 {
		result.Subjects = append(result.Subjects, id)
		//}
		return nil
	})
}

func (x *GenjiNoteMap) Get(subject uint64) (*notespb.Info, error) {
	query, err := x.db.Query("SELECT subject.id, value FROM topics")
	if err != nil {
		return nil, err
	}
	defer query.Close()
	var info notespb.Info
	return &info, query.Iterate(func(doc document.Document) error {
		return document.StructScan(doc, &info)
	})
}

func (x *GenjiNoteMap) Set(info *notespb.Info) error {
	id := info.GetSubject().GetId()
	err := x.db.Exec(`DELETE FROM topics WHERE subject.id = ?`, id)
	if err != nil {
		return err
	}
	return x.db.Exec(`INSERT INTO topics VALUES ?`, info)
}

type NoteSet struct {
	Subjects []uint64
	Infos    map[uint64]*notespb.Info
}
