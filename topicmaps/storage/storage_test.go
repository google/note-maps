package storage

import (
	"io/ioutil"
	"os"
	"testing"

	"github.com/google/note-maps/kv"
	"github.com/google/note-maps/kv/badger"
	"github.com/google/note-maps/topicmaps/kvschema"
)

func TestCreateTopicMap(t *testing.T) {
	dir, err := ioutil.TempDir("", "TestNew-*")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(dir)
	db, err := badger.Open(badger.DefaultOptions(dir))
	if err != nil {
		t.Fatal(err)
	}
	txn := db.NewTransaction(true)
	defer txn.Discard()
	s := Store{kvschema.Store{Store: db.NewStore(txn)}}
	stored, err := s.CreateTopicMap()
	if err != nil {
		t.Error(err)
	} else if stored == nil {
		t.Error("want not-nil, got nil")
	}
	txn.Commit()
	txn = db.NewTransaction(false)
	defer txn.Discard()
	s = Store{kvschema.Store{Store: db.NewStore(txn)}}
	gots, err := s.GetTopicMapInfoSlice([]kv.Entity{kv.Entity(stored.TopicMap)})
	if err != nil {
		t.Error(err)
	} else if len(gots) != 1 {
		t.Error("want 1 result, got", len(gots))
	} else if gots[0].String() != stored.String() {
		t.Errorf("want %s, got %s", stored, &gots[0])
	}
}
