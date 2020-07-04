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

// Package genji implements notes/pbdb interfaces to store Note Maps in a Genji
// database.
package genji

import (
	"github.com/google/note-maps/notes"
	"github.com/google/note-maps/notes/pbdb"
	"github.com/google/note-maps/notes/pbdb/pb"

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
	db.Exec("CREATE TABLE topics20200701")
	return &GenjiNoteMap{db}, nil
}

func (x *GenjiNoteMap) NewReaderTransaction() pbdb.DbReaderTransaction {
	t, err := x.db.Begin(false)
	return &readerTransaction{t, err}
}

func (x *GenjiNoteMap) NewReadWriterTransaction() pbdb.DbReadWriterTransaction {
	t, err := x.db.Begin(true)
	return &writerTransaction{readerTransaction{t, err}}
}

func (x *GenjiNoteMap) Close() error {
	return x.db.Close()
}

type readerTransaction struct {
	t      *genji.Tx
	broken error
}

func whereIds(ids []uint64) (sql string, args []interface{}) {
	for i, id := range ids {
		if i > 0 {
			sql += " OR"
		}
		sql += " id = ?"
		args = append(args, id)
	}
	return sql, args
}

func (r readerTransaction) Load(ids ...uint64) ([]*pb.Note, error) {
	if r.broken != nil {
		return nil, r.broken
	}
	if len(ids) == 0 {
		return nil, nil
	}
	sql, args := whereIds(ids)
	query, err := r.t.Query(`SELECT * FROM topics20200701 WHERE`+sql, args...)
	if err != nil {
		return nil, err
	}
	defer query.Close()
	var ns []*pb.Note
	err = query.Iterate(func(doc document.Document) error {
		var n pb.Note
		err := document.StructScan(doc, &n)
		if err != nil {
			return err
		}
		ns = append(ns, &n)
		return nil
	})
	return ns, err
}

func (r readerTransaction) Find(q *notes.Query) ([]uint64, error) {
	if r.broken != nil {
		return nil, r.broken
	}
	query, err := r.t.Query("SELECT id FROM topics20200701")
	if err != nil {
		return nil, err
	}
	defer query.Close()
	var ids []uint64
	err = query.Iterate(func(doc document.Document) error {
		var n pb.Note
		if err := document.StructScan(doc, &n); err != nil {
			return err
		}
		ids = append(ids, n.GetId())
		return nil
	})
	return ids, err
}

func (r readerTransaction) Discard() { r.t.Rollback() }

type writerTransaction struct {
	readerTransaction
}

func (w writerTransaction) Store(ns []*pb.Note) error {
	if w.broken != nil {
		return w.broken
	}
	for _, n := range ns {
		id := n.GetId()
		err := w.t.Exec(`DELETE FROM topics20200701 WHERE subject.id = ?`, id)
		if err != nil {
			return err
		}
		err = w.t.Exec(`INSERT INTO topics20200701 VALUES ?`, n)
		if err != nil {
			return err
		}
	}
	return nil
}
func (w writerTransaction) Delete(ids []uint64) error {
	if w.broken != nil {
		return w.broken
	}
	sql, args := whereIds(ids)
	return w.t.Exec(`DELETE FROM topics20200701 WHERE `+sql, args...)
}
func (w writerTransaction) Commit() error {
	if w.broken != nil {
		return w.broken
	}
	return w.t.Commit()
}
