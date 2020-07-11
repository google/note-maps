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

package main

import (
	"bytes"
	"context"
	"flag"
	"strings"
	"testing"

	//"github.com/google/note-maps/notes"
	"github.com/google/note-maps/notes/genji"
	"github.com/google/note-maps/notes/pbdb"
	"github.com/google/subcommands"
)

type noCloseDB struct{ *genji.GenjiNoteMap }

func (noCloseDB) Close() error { return nil }

func TestIntegration_SetFindGet(t *testing.T) {
	ctx := context.Background()
	db, err := genji.Open(":memory:")
	if err != nil {
		t.Fatal(err)
	}
	var (
		nm    = pbdb.NewNoteMap(noCloseDB{db})
		cfg   = Config{overrideDb: nm}
		find  = findCmd{&cfg}
		set   = setCmd{&cfg}
		flags = flag.NewFlagSet("", flag.PanicOnError)
		cmdr  = subcommands.NewCommander(flags, "testing")
	)
	cmdr.Register(&find, "")
	cmdr.Register(&set, "")
	exec := func(args ...string) (string, subcommands.ExitStatus) {
		buf := bytes.NewBuffer(nil)
		cfg.output = buf
		flags.Parse(args)
		status := cmdr.Execute(ctx)
		return buf.String(), status
	}
	if o, s := exec("set", "note: &42\n- is: hello"); s != subcommands.ExitSuccess {
		t.Fatal("failed to set initial note")
	} else {
		expect := `42` + "\n"
		if o != expect {
			t.Fatalf("expected %#v, got %#v", expect, o)
		}
	}
	if o, s := exec(`find`); s != subcommands.ExitSuccess {
		t.Fatal("failed to set initial note")
	} else {
		expect := strings.Join([]string{
			"---",
			"note: &42",
			"    - is: hello",
			"---",
		}, "\n") + "\n"
		if o != expect {
			t.Fatalf("expected %#v, got %#v", expect, o)
		}
	}
}
