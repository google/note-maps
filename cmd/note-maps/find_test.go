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
	"testing"

	"github.com/google/subcommands"
)

func TestFindCmd(t *testing.T) {
	t.Skip()
	ctx := context.Background()
	flag.NewFlagSet("", flag.PanicOnError)
	flag.CommandLine.Parse([]string{"-db=:memory:", "find"})
	if subcommands.Execute(ctx) != subcommands.ExitSuccess {
		t.Fatal("expected success with find")
	}
}
