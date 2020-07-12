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

type dontClose struct{ *genji.GenjiNoteMap }

func (dontClose) Close() error { return nil }

type Command interface {
	subcommands.Command
	SetConfig(*Config)
}

type CommandForTest struct {
	db           *genji.GenjiNoteMap
	cmd          Command
	args         []string
	input        string
	expectExit   subcommands.ExitStatus
	expectOutput string
}

func (c CommandForTest) Exec(t *testing.T) {
	ctx := context.Background()
	var (
		flags  = flag.NewFlagSet("", flag.PanicOnError)
		cmdr   = subcommands.NewCommander(flags, t.Name())
		nm     = pbdb.NewNoteMap(dontClose{c.db})
		output = bytes.NewBuffer(nil)
		cfg    = Config{
			overrideDb: nm,
			input:      bytes.NewReader([]byte(c.input)),
			output:     output,
		}
	)
	c.cmd.SetConfig(&cfg)
	cmdr.Register(c.cmd, "")
	flags.Parse(append([]string{c.cmd.Name()}, c.args...))
	exit := cmdr.Execute(ctx)
	if exit != c.expectExit {
		t.Error("got exit status", exit, "expected exit status", c.expectExit)
	}
	if string(output.Bytes()) != c.expectOutput {
		t.Fatalf("got output %#v, expected %#v", string(output.Bytes()), c.expectOutput)
	}
}

func TestIntegration_SetFindGet(t *testing.T) {
	db, err := genji.Open(":memory:")
	if err != nil {
		t.Fatal(err)
	}
	t.Run("set initial note",
		CommandForTest{
			db:           db,
			cmd:          &setCmd{},
			input:        "note: &42\n- is: hello",
			expectOutput: `42` + "\n",
		}.Exec)
	t.Run("find initial note",
		CommandForTest{
			db:  db,
			cmd: &findCmd{},
			expectOutput: strings.Join([]string{
				"---",
				"note: &42",
				"    - is: hello",
				"---",
			}, "\n") + "\n",
		}.Exec)
}
