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
	"io/ioutil"
	"os"
	"runtime/debug"
	"sync/atomic"
	"testing"

	"github.com/google/note-maps/kv"
	"github.com/google/note-maps/kv/badger"
	"github.com/google/note-maps/kv/memory"
)

// NewDB returns a new kv.DB suitable for use in a unit test.
//
// It's still important to call Close() in order to delete any temporary files
// created by the kv.Txn.
func NewDB(t *testing.T) kv.DB {
	dir, err := ioutil.TempDir("", "kvtest-badger")
	if err != nil {
		t.Fatal(err)
	}
	db, err := badger.Open(badger.DefaultOptions(dir).WithLogger(badgerLogger{t}))
	if err != nil {
		os.RemoveAll(dir)
		t.Fatal(err)
	}
	return &tmpDB{db, dir}
}

type tmpDB struct {
	kv.DB
	dir string
}

func (db *tmpDB) Close() error {
	db.DB.Close()
	os.RemoveAll(db.dir)
	return nil
}

// New returns a new kv.Txn suitable for use in a unit test.
//
// It's still important to call Close() in order to delete any temporary files
// created by the kv.Txn.
func New(t *testing.T) kv.TxnCommitDiscarder {
	if testing.Short() {
		return memory.New()
	}
	dir, err := ioutil.TempDir("", "kvtest-badger")
	if err != nil {
		t.Fatal(err)
	}
	b, err := badger.Open(badger.DefaultOptions(dir).WithLogger(badgerLogger{t}))
	if err != nil {
		os.RemoveAll(dir)
		t.Fatal(err)
	}
	return &tmpTxn{
		TxnCommitDiscarder: b.NewTxn(true),
		discard: func() {
			b.Close()
			os.RemoveAll(dir)
		},
	}
}

type tmpTxn struct {
	kv.TxnCommitDiscarder
	discard func()
}

func (s *tmpTxn) Discard() {
	s.TxnCommitDiscarder.Discard()
	s.discard()
}

type badgerLogger struct {
	*testing.T
}

func (l badgerLogger) Errorf(f string, v ...interface{})   { l.Logf(f, v...) }
func (l badgerLogger) Warningf(f string, v ...interface{}) { l.Logf(f, v...) }
func (l badgerLogger) Infof(f string, v ...interface{})    { l.Logf(f, v...) }
func (l badgerLogger) Debugf(f string, v ...interface{})   { l.Logf(f, v...) }

// NewFlaky returns a new Flaky that wraps the given a kv.Txn and will fail
// when the count of error checks reaches failAtCount.
//
// If failAtCount is zero, the resulting Flaky will never deliberately return
// an error.
func NewFlaky(t *testing.T, failAtCount int) *Flaky {
	return &Flaky{
		Txn:         memory.New(),
		failAtCount: failAtCount,
		err:         Flake(failAtCount),
	}
}

// Flake is the type of error returned by a Flaky store.
type Flake int

// Error returns a simple human-readable string describing this flake.
func (f Flake) Error() string { return fmt.Sprintf("flake#%d", int(f)) }

// Flaky is a kv.Txn implemention that
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
	kv.Txn
	errCheckCount int32
	failAtCount   int
	err           error
	stackTrace    string
}

// ErrCheckCount returns the total number of error checks this Flaky has
// counted so far.
func (s *Flaky) ErrCheckCount() int {
	return int(atomic.LoadInt32(&s.errCheckCount))
}

// StackTrace returns a formatted stacktrace taken from the moment an error was
// returned.
func (s *Flaky) StackTrace() string {
	return s.stackTrace
}

func (s *Flaky) fail() bool {
	f := int(atomic.AddInt32(&s.errCheckCount, 1)) == s.failAtCount
	if f {
		s.stackTrace = string(debug.Stack())
	}
	return f
}

// Alloc fails if the count of error checks has reached failAtCount.
func (s *Flaky) Alloc() (kv.Entity, error) {
	if s.fail() {
		return 0, s.err
	}
	return s.Txn.Alloc()
}

// Get fails if the count of error checks has reached failAtCount.
func (s *Flaky) Get(k []byte, f func([]byte) error) error {
	if s.fail() {
		return s.err
	}
	return s.Txn.Get(k, f)
}

// Set fails if the count of error checks has reached failAtCount.
func (s *Flaky) Set(k, v []byte) error {
	if s.fail() {
		return s.err
	}
	return s.Txn.Set(k, v)
}

// Deflake calls test repeatedly to check that all errors returned from
// kv.Txn methods produce failures in the test.
//
// Deflake(t, test) will pass if and only if: test completes when given a
// well-behaved kv.Txn that never returns errors, and test panics when given
// a kv.Txn that returns errors "unpredictably".
//
// The test func must use panic to communicate failures. It might be nice to
// use a *testing.T like sane people do, but this approach requires a test that
// can succeed successfully when the kv.Txn doesn't return any errors, and
// fail successfully when it does return an error. Unfortunately, the testing
// package doesn't support this, and we have to panic instead.
func Deflake(t *testing.T, test func(kv.Txn)) {
	successful := NewFlaky(t, 0)
	t.Run("success", func(*testing.T) {
		test(successful)
	})
	for want := 1; want < successful.ErrCheckCount(); want++ {
		t.Run(Flake(want).Error(), func(t *testing.T) {
			flaky := NewFlaky(t, want)
			defer func() {
				if r := recover(); r == nil {
					t.Error("error did not cause test failure: " + flaky.StackTrace())
				}
			}()
			test(flaky)
		})
	}
}
