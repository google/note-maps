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
	"os"

	"github.com/google/note-maps/notes"
	"github.com/google/note-maps/notes/yaml"
	"github.com/google/subcommands"
)

type findCmd struct {
	cfg *Config
}

func (*findCmd) Name() string     { return "find" }
func (*findCmd) Synopsis() string { return "Find notes matching a query." }
func (*findCmd) Usage() string {
	return `find <query>:
  Print matching notes to stdout.
`
}
func (c *findCmd) SetFlags(f *flag.FlagSet) {
	//f.BoolVar(&c.capitalize, "capitalize", false, "capitalize output")
}
func (c *findCmd) Execute(_ context.Context, f *flag.FlagSet, _ ...interface{}) subcommands.ExitStatus {
	db, err := c.cfg.open()
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		return subcommands.ExitFailure
	}
	defer db.Close()
	ns, err := db.Find(&notes.Query{})
	for _, n := range ns {
		bs, err := yaml.MarshalNote(n)
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			return subcommands.ExitFailure
		}
		c.cfg.output.Write([]byte("---\n"))
		c.cfg.output.Write(bs)
	}
	if len(ns) > 0 {
		c.cfg.output.Write([]byte("---\n"))
	}
	return subcommands.ExitSuccess
}

func init() {
	subcommands.Register(&findCmd{&globalConfig}, "notes")
}
