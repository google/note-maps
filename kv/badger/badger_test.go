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

package badger

import (
	"io/ioutil"
	"os"
	"testing"
)

func TestNew(t *testing.T) {
	dir, err := ioutil.TempDir("", "TestNew-*")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(dir)
	db, err := Open(DefaultOptions(dir))
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	txn := db.NewTxn(true)
	defer txn.Discard()
	want := "value"
	if err = txn.Set([]byte("key"), []byte(want)); err != nil {
		t.Fatal(err)
	}
	var got string
	err = txn.Get([]byte("key"), func(bs []byte) error {
		got = string(bs)
		return nil
	})
	if err != nil {
		t.Fatal(err)
	} else if want != got {
		t.Errorf("want %#v, got %#v", want, got)
	}
}
