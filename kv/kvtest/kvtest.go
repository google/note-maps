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

// Package kvtest provides some utilities to help test packages that use kv.
package kvtest

import (
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"sync/atomic"
	"testing"

	"github.com/google/note-maps/kv"
	"github.com/google/note-maps/kv/badger"
	"github.com/google/note-maps/kv/memory"
)

// New returns a new kv.Store suitable for use in a unit test.
//
// It's still important to call Close() in order to delete any temporary files
// created by the kv.Store.
func New(t *testing.T) StoreCloser {
	if testing.Short() {
		return &tmpStore{
			Store:  memory.New(),
			closer: func() error { return nil },
		}
	} else {
		dir, err := ioutil.TempDir("", "kvtest-badger")
		if err != nil {
			t.Fatal(err)
		}
		b, err := badger.Open(badger.DefaultOptions(dir).WithLogger(badgerLogger{t}))
		if err != nil {
			os.RemoveAll(dir)
			t.Fatal(err)
		}
		txn := b.NewTransaction(true)
		return &tmpStore{
			Store: b.NewStore(txn),
			closer: func() error {
				txn.Discard()
				b.Close()
				os.RemoveAll(dir)
				return nil
			},
		}
	}
}

type StoreCloser interface {
	kv.Store
	io.Closer
}

type tmpStore struct {
	kv.Store
	closer func() error
}

func (s *tmpStore) Close() error {
	return s.closer()
}

type badgerLogger struct {
	*testing.T
}

func (l badgerLogger) Errorf(f string, v ...interface{})   { l.Logf(f, v...) }
func (l badgerLogger) Warningf(f string, v ...interface{}) { l.Logf(f, v...) }
func (l badgerLogger) Infof(f string, v ...interface{})    { l.Logf(f, v...) }
func (l badgerLogger) Debugf(f string, v ...interface{})   { l.Logf(f, v...) }

// NewFlaky returns a new Flaky that wraps the given a kv.Store and will fail
// when the count of error checks reaches failAtCount.
//
// If failAtCount is zero, the resulting Flaky will never deliberately return
// an error.
func NewFlaky(t *testing.T, failAtCount int) *Flaky {
	return &Flaky{
		Store:       memory.New(),
		failAtCount: failAtCount,
		err:         Flake(failAtCount),
	}
}

// Flake is the type of error returned by a Flaky store.
type Flake int

// Error returns a simple human-readable string describing this flake.
func (f Flake) Error() string { return fmt.Sprintf("flake#%d", int(f)) }

// Flaky is a kv.Store implemention that
//
// Flaky counts each call to any method that could return an error as another
// error check. When, during a call to such a method, the number of error
// checks reaches a preset value, then that call will return an error.
//
// Usage might involve running a test once with failAtCount set to zero to test
// the successful case and count the number of error checks, and then to run it
// again for each possible value of failAtCount from 1 to the number of error
// checks, to make sure all errors are handled appropriately.
type Flaky struct {
	kv.Store
	errCheckCount int32
	failAtCount   int
	err           error
}

// ErrCheckCount returns the total number of error checks this Flaky has
// counted so far.
func (s *Flaky) ErrCheckCount() int {
	return int(atomic.LoadInt32(&s.errCheckCount))
}

func (s *Flaky) fail() bool {
	return int(atomic.AddInt32(&s.errCheckCount, 1)) == s.failAtCount
}

// Alloc fails if the count of error checks has reached failAtCount.
func (s *Flaky) Alloc() (kv.Entity, error) {
	if s.fail() {
		return 0, s.err
	}
	return s.Store.Alloc()
}

// Get fails if the count of error checks has reached failAtCount.
func (s *Flaky) Get(k []byte, f func([]byte) error) error {
	if s.fail() {
		return s.err
	}
	return s.Store.Get(k, f)
}

// Set fails if the count of error checks has reached failAtCount.
func (s *Flaky) Set(k, v []byte) error {
	if s.fail() {
		return s.err
	}
	return s.Store.Set(k, v)
}
