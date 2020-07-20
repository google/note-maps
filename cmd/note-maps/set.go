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
	"context"
	"flag"
	"fmt"
	"io"
	"io/ioutil"
	"os"

	"github.com/google/note-maps/notes"
	"github.com/google/note-maps/notes/yaml"
	"github.com/google/subcommands"
)

type setCmd struct {
	cfg *Config
}

func (*setCmd) Name() string     { return "set" }
func (*setCmd) Synopsis() string { return "Set the info about a subject." }
func (*setCmd) Usage() string {
	return `set:
  Import a note in YAML format.
`
}
func (c *setCmd) SetConfig(cfg *Config) { c.cfg = cfg }
func (c *setCmd) SetFlags(f *flag.FlagSet) {
	//f.BoolVar(&c.capitalize, "capitalize", false, "capitalize output")
}
func (c *setCmd) Execute(_ context.Context, f *flag.FlagSet, _ ...interface{}) subcommands.ExitStatus {
	var (
		r   io.Reader
		err error
	)
	if len(f.Args()) > 1 {
		return subcommands.ExitUsageError
	} else if len(f.Args()) == 1 {
		r, err = os.Open(f.Args()[0])
		if err != nil {
			fmt.Fprintln(os.Stderr, "set: while opening", f.Args()[0], ":", err)
			return subcommands.ExitFailure
		}
	} else {
		r = c.cfg.input
	}
	input, err := ioutil.ReadAll(r)
	if err != nil {
		fmt.Fprintln(os.Stderr, "set: while reading input:", err)
		return subcommands.ExitFailure
	}
	var (
		stage notes.Stage
		note  = stage.Note(notes.EmptyID)
	)
	err = yaml.UnmarshalNote(input, note)
	if err != nil {
		fmt.Fprintln(os.Stderr, "set: while parsing input", err)
		return subcommands.ExitFailure
	}
	if note.GetID() == notes.EmptyID {
		fmt.Fprintln(os.Stderr, "set: a non-zero id is required")
		return subcommands.ExitFailure
	}

	db, err := c.cfg.open()
	if err != nil {
		fmt.Fprintln(os.Stderr, "set: while opening db:", err)
		return subcommands.ExitFailure
	}
	defer db.Close()

	if err = db.IsolatedWrite(func(w notes.FindLoadPatcher) error {
		return w.Patch(stage.Ops)
	}); err != nil {
		fmt.Fprintln(os.Stderr, "set: while applying change:", err)
		return subcommands.ExitFailure
	}

	fmt.Fprintln(c.cfg.output, note.GetID())
	return subcommands.ExitSuccess
}

func init() {
	subcommands.Register(&setCmd{&globalConfig}, "notes")
}
