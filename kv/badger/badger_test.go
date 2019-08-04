package badger

import (
	"io/ioutil"
	"os"
	"testing"

	"github.com/google/note-maps/kv"
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
	txn := db.NewTransaction(true)
	defer txn.Discard()
	var s kv.Txn = db.NewTxn(txn)
	want := "value"
	if err = s.Set([]byte("key"), []byte(want)); err != nil {
		t.Fatal(err)
	}
	var got string
	err = s.Get([]byte("key"), func(bs []byte) error {
		got = string(bs)
		return nil
	})
	if err != nil {
		t.Fatal(err)
	} else if want != got {
		t.Errorf("want %#v, got %#v", want, got)
	}
}
