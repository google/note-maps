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
// github.com/google/note-maps/notes interfaces.
package textile

import (
	"context"
	"encoding/json"
	"errors"
	"path/filepath"
	"sync"

	"github.com/google/note-maps/notes"
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

// NoteMap is meant to implement the notes.NoteMap interface.
type NoteMap struct {
	t        *db.DB
	initOnce sync.Once
	note     *db.Collection
	broke    error
}

// Open creates a NoteMap that replicates through net n.
//
// All options are optional, but if non are provided the database may not be
// reusable.
func Open(ctx context.Context, n app.Net, opts ...Option) (*NoteMap, error) {
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
		db.WithNewThreadKey(key), db.WithNewRepoPath(path))
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
	return &NoteMap{t: d}, nil
}

func (nm *NoteMap) init() error {
	nm.initOnce.Do(func() {
		cs := nm.t.ListCollections()
		for _, c := range cs {
			if c.GetName() == "Notes" {
				nm.note = c
			}
		}
		if nm.note != nil {
			return
		}
		var err error
		nm.note, err = nm.t.NewCollection(db.CollectionConfig{
			Name:   "Note",
			Schema: util.SchemaFromInstance(&record{}, false),
		})
		if err != nil {
			nm.broke = wrapError("creating note schema in database", err)
		}
	})
	return nm.broke
}

func (nm *NoteMap) find(q *db.Query) ([]notes.Note, error) {
	bss, err := nm.note.Find(q)
	if err != nil {
		return nil, err
	}
	notes := make([]notes.Note, len(bss))
	for i, bs := range bss {
		var r record
		if err = json.Unmarshal(bs, &r); err != nil {
			return nil, err
		}
		notes[i] = &note{record: r, loaded: true}
	}
	return notes, nil
}

func (nm *NoteMap) loadRecord(id notes.ID, r *record) error {
	bs, err := nm.note.FindByID(core.InstanceID(id))
	if err != nil {
		return err
	}
	return json.Unmarshal(bs, &r)
}

func (nm *NoteMap) Find(q *notes.Query) ([]notes.Note, error) {
	if err := nm.init(); err != nil {
		return nil, err
	}
	return nm.find(&db.Query{})
}

func (nm *NoteMap) Load(ids []notes.ID) ([]notes.Note, error) {
	if err := nm.init(); err != nil {
		return nil, err
	}
	var q *db.Query
	for _, id := range ids {
		or := db.Where("ID").Eq(id)
		if q == nil {
			q = or
		} else {
			q = q.Or(or)
		}
	}
	found, err := nm.find(&db.Query{})
	if err != nil {
		return nil, err
	}
	id2found := make(map[notes.ID]int)
	for i, n := range found {
		id2found[n.GetID()] = i
	}
	ns := make([]notes.Note, len(ids))
	for i, id := range ids {
		if f, ok := id2found[id]; !ok {
			ns[i] = notes.EmptyNote(id)
		} else {
			ns[i] = found[f]
		}
	}
	return ns, nil
}

func (nm *NoteMap) Patch(ops []notes.Operation) error {
	if err := nm.init(); err != nil {
		return err
	}
	return nm.note.WriteTxn(func(txn *db.Txn) error {
		cache := make(map[notes.ID]*note)
		created := make(map[notes.ID]bool)
		get := func(id notes.ID) (*note, error) {
			if _, ok := cache[id]; !ok {
				cid := core.InstanceID(id)
				bs, err := txn.FindByID(cid)
				if err != nil {
					if err == db.ErrInstanceNotFound {
						var n note
						n.record.ID = cid
						n.loaded = true
						cache[id] = &n
						created[id] = true
					} else {
						return nil, wrapError("loading note "+string(cid), err)
					}
				} else {
					var n note
					if err := json.Unmarshal(bs, &n.record); err != nil {
						return nil, wrapError("parsing note "+string(cid)+" from storage", err)
					}
					n.loaded = true
					cache[id] = &n
				}
			}
			return cache[id], nil
		}
		for _, op := range ops {
			switch o := op.(type) {
			case notes.AddContent:
				n, err := get(o.ID)
				if err != nil {
					return err
				}
				n.record.Contents = append(
					n.record.Contents,
					o.Add)
			case notes.SetValue:
				n, err := get(o.ID)
				if err != nil {
					return err
				}
				n.record.ValueString = o.Lexical
				n.record.ValueType = o.Datatype
			default:
				panic("unrecognized op type")
			}
		}
		for _, n := range cache {
			bs, err := json.Marshal(n.record)
			if err != nil {
				return wrapError("marshalling updated note for storage", err)
			}
			if created[n.GetID()] {
				actual, err := txn.Create(bs)
				if err != nil {
					return wrapError("while saving note", err)
				}
				intended := string(n.GetID())
				if string(actual[0]) != intended {
					return errors.New("created note " + string(actual[0]) + ", intended " + intended)
				}
			} else {
				if err := txn.Save(bs); err != nil {
					return wrapError("while saving note", err)
				}
			}
		}
		return nil
	})
}

func (nm *NoteMap) Close() error { return nm.t.Close() }

type record struct {
	ID          core.InstanceID `json:"_id"`
	Types       []notes.ID      `json:"types,omitempty"`
	Supertypes  []notes.ID      `json:"super_types,omitempty"`
	ValueString string          `json:"value_string,omitempty"`
	ValueType   notes.ID        `json:"value_type,omitempty"`
	Contents    []notes.ID      `json:"contents,omitempty"`
}

type note struct {
	record
	loaded bool
	mu     sync.Mutex
	loader *NoteMap
}

func (n *note) load() error {
	n.mu.Lock()
	defer n.mu.Unlock()
	var id = notes.ID(n.record.ID)
	if id.Empty() {
		return errors.New("can't load note with empty ID")
	}
	if !n.loaded {
		err := n.loader.loadRecord(id, &n.record)
		if err != nil {
			return err
		}
		n.loaded = true
	}
	return nil
}

func (n *note) GetID() notes.ID { return notes.ID(n.ID) }

func (n *note) GetTypes() ([]notes.Note, error) {
	if err := n.load(); err != nil {
		return nil, err
	}
	ns := make([]notes.Note, len(n.Types))
	for i, id := range n.Types {
		ns[i] = &note{record: record{ID: core.InstanceID(id)}}
	}
	return ns, nil
}

func (n *note) GetSupertypes() ([]notes.Note, error) {
	return notes.EmptyNote(0).GetSupertypes()
}

func (n *note) GetValue() (string, notes.Note, error) {
	if err := n.load(); err != nil {
		return "", nil, err
	}
	return n.record.ValueString, &note{
		record: record{ID: core.InstanceID(n.record.ValueType)},
		loader: n.loader,
	}, nil
}

func (n *note) GetContents() ([]notes.Note, error) {
	return notes.EmptyNote(0).GetContents()
}
