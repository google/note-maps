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

	"github.com/99designs/keyring"
	"github.com/google/note-maps/note"
	"github.com/google/note-maps/note/textile"
	"github.com/google/subcommands"
)

type Config struct {
	Db         string
	overrideDb note.IsolatedReadWriteCloser
	input      io.Reader
	output     io.Writer
	dataHome   string
	thread     string
}

type addCloser struct {
	note.IsolatedReadWriteCloser
	closer func() error
}

func (c addCloser) Close() error {
	e0 := c.IsolatedReadWriteCloser.Close()
	e1 := c.closer()
	if e0 != nil {
		return e0
	}
	return e1
}

func (c *Config) open() (note.IsolatedReadWriteCloser, error) {
	if c.overrideDb != nil {
		return c.overrideDb, nil
	}
	baseDir := filepath.Join(c.dataHome, "textile")
	n, err := textile.DefaultNetwork(baseDir)
	if err != nil {
		return nil, err
	}
	kr, err := keyring.Open(keyring.Config{
		ServiceName: "Note Maps",
	})
	if err != nil {
		return nil, err
	}
	opts := []textile.Option{
		textile.WithBaseDirectory(c.dataHome),
		textile.WithGetSecret(func(key string) ([]byte, error) {
			item, err := kr.Get(key)
			if err != nil {
				return nil, err
			}
			return item.Data, nil
		}),
		textile.WithSetSecret(func(key string, secret []byte) error {
			return kr.Set(keyring.Item{
				Key:         key,
				Data:        secret,
				Label:       "keys for " + key,
				Description: "ThreadsDB encryption keys",
			})
		}),
	}
	if c.Db != "" {
		opts = append(opts, textile.WithPath(c.Db))
	}
	if c.thread != "" {
		opts = append(opts, textile.WithThread(c.thread))
	}
	nm, err := textile.Open(context.Background(), n, opts...)
	if err != nil {
		return nil, err
	}
	return addCloser{nm, n.Close}, nil
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
	)
	globalConfig.dataHome = os.Expand(
		filepath.Join("$XDG_DATA_HOME", "note-maps"),
		getEnv)
	os.MkdirAll(globalConfig.dataHome, 0700) // ignore error, it might not matter.
	flag.StringVar(&globalConfig.Db, "db", "", "location for data files")
	flag.StringVar(&globalConfig.thread, "thread_id", "", "ThreadsDB thread id")
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
