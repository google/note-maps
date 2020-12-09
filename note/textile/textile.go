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

// Package textile uses Textileio ThreadsDB to implement the
// github.com/google/note-maps/note interfaces.
package textile

import (
	"context"
	"encoding/json"
	"errors"
	"path/filepath"
	"sync"

	"github.com/google/note-maps/note"
	"github.com/google/note-maps/note/truncated"
	"github.com/textileio/go-threads/common"
	"github.com/textileio/go-threads/core/app"
	core "github.com/textileio/go-threads/core/db"
	"github.com/textileio/go-threads/core/thread"
	"github.com/textileio/go-threads/db"
	"github.com/textileio/go-threads/util"
)

type textileError struct {
	m string
	w error
}

func (e textileError) Error() string    { return "notes/textile: " + e.m + ": " + e.w.Error() }
func (e textileError) Unwrap() error    { return e.w }
func wrapError(m string, w error) error { return textileError{m, w} }

type GetSecret func(key string) (secret []byte, err error)
type SetSecret func(key string, secret []byte) error

type Options struct {
	// BaseDirectory is a directory within which many databases might stored.
	//
	// It might typically be something like "$XDG_DATA_HOME/$argv[0]"
	BaseDirectory string

	// Thread is a printable multibase representation of the thread identifier.
	Thread string

	// Key is a printable representation of the thread encryption keys for
	// service/replication and, optionally, for reading.
	Key string

	// GetSecret will be used to load the thread encryption keys if none are
	// provided in the Key field.
	GetSecret

	// SetSecret will be used to store the thread encyrption keys.
	SetSecret
}

func (o *Options) expand() error {
	// Resolve the thread id:
	randomNewThread := o.Thread == ""
	if randomNewThread {
		o.Thread = thread.NewIDV1(thread.Raw, 32).String()
	}
	// Resolve the thread encryption keys:
	if o.Key == "" {
		if !randomNewThread && o.GetSecret != nil {
			secret, err := o.GetSecret(o.Thread)
			if err != nil {
				return wrapError("loading key for "+o.Thread, err)
			}
			key, err := thread.KeyFromBytes(secret)
			if err != nil {
				return wrapError("decoding loaded key for "+o.Thread, err)
			}
			o.Key = key.String()
		}
		if o.Key == "" {
			o.Key = thread.NewRandomKey().String()
		}
	}
	return nil
}

type Option func(*Options)

func WithBaseDirectory(d string) Option {
	return func(o *Options) { o.BaseDirectory = d }
}
func WithPath(p string) Option {
	return func(o *Options) {
		o.BaseDirectory, o.Thread = filepath.Split(p)
	}
}

func WithThread(t string) Option { return func(o *Options) { o.Thread = t } }
func WithGetSecret(f GetSecret) Option {
	return func(o *Options) { o.GetSecret = f }
}
func WithSetSecret(f SetSecret) Option {
	return func(o *Options) { o.SetSecret = f }
}

// DefaultNetwork is a convenience function to build a
// github.com/textileio/core/app.Net for use with Open().
func DefaultNetwork(dir string) (app.Net, error) {
	return common.DefaultNetwork(
		dir,
		common.WithNetDebug(true),
		common.WithNetHostAddr(util.FreeLocalAddr()))
}

// Database is meant to implement the note.IsolatedReadWriteCloser interface.
type Database struct {
	t        *db.DB
	id       thread.ID
	initOnce sync.Once
	note     *db.Collection
	broke    error
}

// Open creates a Database that replicates through net n.
//
// All options are optional, but if non are provided the database may not be
// reusable.
func Open(ctx context.Context, n app.Net, opts ...Option) (*Database, error) {
	var o Options
	for _, opt := range opts {
		opt(&o)
	}
	if err := o.expand(); err != nil {
		return nil, err
	}
	tid, err := thread.Decode(o.Thread)
	if err != nil {
		return nil, wrapError("decoding thread "+o.Thread, err)
	}
	key, err := thread.KeyFromString(o.Key)
	if err != nil {
		return nil, wrapError("parsing thread key", err)
	}
	path := filepath.Join(o.BaseDirectory, o.Thread)
	d, err := db.NewDB(context.Background(), n, tid,
		db.WithNewKey(key), db.WithNewRepoPath(path))
	if err != nil {
		return nil, wrapError("connecting to database", err)
	}
	if o.SetSecret != nil {
		err := o.SetSecret(o.Thread, key.Bytes())
		if err != nil {
			d.Close()
			return nil, wrapError("storing thread key", err)
		}
	}
	return &Database{t: d, id: tid}, nil
}

func (x *Database) init() error {
	x.initOnce.Do(func() {
		cs := x.t.ListCollections()
		for _, c := range cs {
			if c.GetName() == "Note" {
				x.note = c
			}
		}
		if x.note != nil {
			return
		}
		var err error
		x.note, err = x.t.NewCollection(db.CollectionConfig{
			Name:   "Note",
			Schema: util.SchemaFromInstance(&record{}, false),
		})
		if err != nil {
			x.broke = wrapError("creating note schema in database", err)
		}
	})
	return x.broke
}

func (x *Database) Close() error { return x.t.Close() }

func (x *Database) IsolatedRead(f func(r note.FindLoader) error) error {
	if err := x.init(); err != nil {
		return err
	}
	return x.note.ReadTxn(func(t *db.Txn) error {
		r := reader{t}
		lr := truncated.ExpandLoader(r)
		fr := truncated.ExpandFinder(r, lr)
		return f(findloader{fr, lr})
	})
}

func (x *Database) IsolatedWrite(f func(rw note.FindLoadPatcher) error) error {
	if err := x.init(); err != nil {
		return err
	}
	return x.note.WriteTxn(func(t *db.Txn) error {
		r := reader{t}
		lr := truncated.ExpandLoader(r)
		fr := truncated.ExpandFinder(r, lr)
		return f(findloadpatcher{fr, lr, r})
	})
}

func (x *Database) GetThreadID() thread.ID { return x.id }

type (
	reader     struct{ Txn *db.Txn }
	findloader struct {
		note.Finder
		note.Loader
	}
	findloadpatcher struct {
		note.Finder
		note.Loader
		r reader
	}
)

func (r reader) FindNoteIDs(q *note.Query) ([]note.ID, error) {
	recs, err := r.find(&db.Query{})
	if err != nil {
		return nil, err
	}
	ids := make([]note.ID, len(recs))
	for i := range recs {
		ids[i] = note.ID(recs[i].ID)
	}
	return ids, nil
}

func (r reader) find(q *db.Query) ([]record, error) {
	bss, err := r.Txn.Find(q)
	if err != nil {
		return nil, err
	}
	records := make([]record, len(bss))
	for i, bs := range bss {
		if err = json.Unmarshal(bs, &records[i]); err != nil {
			return nil, err
		}
	}
	return records, nil
}

func (r reader) has(id note.ID) (bool, error) {
	return r.Txn.Has(core.InstanceID(id))
}

func (r reader) loadRecord(id note.ID, rec *record) error {
	bs, err := r.Txn.FindByID(core.InstanceID(id))
	if err != nil {
		if errors.Is(err, db.ErrInstanceNotFound) {
			rec.ID = core.InstanceID(id)
			return nil
		}
		return err
	}
	return json.Unmarshal(bs, rec)
}

func (r reader) LoadTruncatedNotes(ids []note.ID) ([]note.TruncatedNote, error) {
	tns := make([]note.TruncatedNote, len(ids))
	for i, id := range ids {
		var rec record
		if err := r.loadRecord(id, &rec); err != nil {
			return nil, err
		}
		tns[i] = note.TruncatedNote{
			ID:          note.ID(rec.ID),
			ValueString: rec.ValueString,
			ValueType:   rec.ValueType,
			Contents:    rec.Contents,
		}
	}
	return tns, nil
}

func (w findloadpatcher) Patch(ops []note.Operation) error {
	stage := note.Stage{
		Ops:  ops,
		Base: w,
	}
	ids := make(map[note.ID]bool)
	for _, op := range ops {
		switch o := op.(type) {
		case note.OpSetValue:
			ids[o.GetID()] = true
		case note.OpContentDelta:
			ids[o.GetID()] = true
		default:
			panic("unrecognized op type")
		}
	}
	var (
		creates, saves [][]byte
	)
	for id := range ids {
		n := stage.Note(id)
		vs, vt, err := n.GetValue()
		if err != nil {
			return wrapError("while calculating resulting state for "+string(id), err)
		}
		cs, err := n.GetContents()
		if err != nil {
			return wrapError("while calculating resulting state for "+string(id), err)
		}
		cids := make([]note.ID, len(cs))
		for i := range cs {
			cids[i] = cs[i].GetID()
		}
		bs, err := json.Marshal(&record{
			ID:          core.InstanceID(id),
			ValueString: vs,
			ValueType:   vt.GetID(),
			Contents:    cids,
		})
		if updating, err := w.r.has(id); err != nil {
			return wrapError("while checking for existence of "+string(id), err)
		} else if updating {
			saves = append(saves, bs)
		} else {
			creates = append(creates, bs)
		}
	}
	if len(creates) > 0 {
		if _, err := w.r.Txn.Create(creates...); err != nil {
			return wrapError("while creating notes", err)
		}
	}
	if len(saves) > 0 {
		if err := w.r.Txn.Save(saves...); err != nil {
			return wrapError("while saving notes", err)
		}
	}
	return nil
}

type record struct {
	ID          core.InstanceID `json:"_id"`
	ValueString string          `json:"value_string,omitempty"`
	ValueType   note.ID         `json:"value_type,omitempty"`
	Contents    []note.ID       `json:"contents,omitempty"`
}
