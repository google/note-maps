package notes

import (
	"testing"
)

func TestEmptyId(t *testing.T) {
	var empty uint64
	if EmptyId != empty {
		t.Fatal("EmptyId is not the default value")
	}
}

func TestEmptyNote(t *testing.T) {
	var n Note = EmptyNote(7)
	if id := n.GetId(); id != 7 {
		t.Errorf("got %v, expected %v", id, 7)
	}
	if ns, err := n.GetTypes(); err != nil {
		t.Errorf("got %v, expected nil", err)
	} else if len(ns) != 0 {
		t.Errorf("got %#v, expected empty slice", ns)
	}
	if ns, err := n.GetSupertypes(); err != nil {
		t.Errorf("got %v, expected nil", err)
	} else if len(ns) != 0 {
		t.Errorf("got %#v, expected empty slice", ns)
	}
	if s, n, err := n.GetValue(); err != nil {
		t.Errorf("got %v, expected nil", err)
	} else if s != "" || n.GetId() != EmptyId {
		t.Errorf("got %#v, %#v, expected empty string and zero note", s, n)
	}
	if ns, err := n.GetContents(); err != nil {
		t.Errorf("got %v, expected nil", err)
	} else if len(ns) != 0 {
		t.Errorf("got %#v, expected empty slice", ns)
	}
}
