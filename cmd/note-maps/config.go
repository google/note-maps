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
	"io"
	"os"
	"path/filepath"

	"github.com/google/note-maps/notes"
	"github.com/google/note-maps/notes/genji"
	"github.com/google/note-maps/notes/pbdb"
	"github.com/google/subcommands"
)

type Config struct {
	Db         string
	overrideDb notes.NoteMap
	input      io.Reader
	output     io.Writer
}

func (c *Config) open() (notes.NoteMap, error) {
	if c.overrideDb != nil {
		return c.overrideDb, nil
	}
	db, err := genji.Open(c.Db)
	if err != nil {
		return nil, err
	}
	return pbdb.NewNoteMap(db), nil
}

var (
	globalConfig = Config{
		input:  os.Stdin,
		output: os.Stdout,
	}
)

func init() {
	var (
		envDefaults = map[string]string{
			"XDG_DATA_HOME": os.ExpandEnv(filepath.Join("$HOME", ".local", "share")),
		}
		getEnv = func(n string) string {
			v := os.Getenv(n)
			if v == "" {
				v, _ = envDefaults[n]
			}
			return v
		}
		dataHome = os.Expand(
			filepath.Join("$XDG_DATA_HOME", "note-maps"),
			getEnv)
	)
	os.MkdirAll(dataHome, 0700) // ignore error, it might not matter.
	flag.StringVar(&globalConfig.Db, "db", filepath.Join(dataHome, "notes.db"), "location for data files")
}

type configCmd struct {
	cfg *Config
}

func (*configCmd) Name() string     { return "config" }
func (*configCmd) Synopsis() string { return "Get or set configuration settings." }
func (*configCmd) Usage() string {
	return `config <...?>:
  Get or set configuration settings.
`
}
func (c *configCmd) SetFlags(f *flag.FlagSet) {
	//f.BoolVar(&c.capitalize, "capitalize", false, "capitalize output")
}
func (c *configCmd) Execute(_ context.Context, f *flag.FlagSet, _ ...interface{}) subcommands.ExitStatus {
	return subcommands.ExitSuccess
}

func init() {
	subcommands.Register(&configCmd{&globalConfig}, "")
}
