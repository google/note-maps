// Copyright 2019 Google LLC
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

// Package store provides data storage for topic maps in a key-value store.
package store

import (
	"github.com/google/note-maps/kv"
	"github.com/google/note-maps/store/command"
	"github.com/google/note-maps/store/models"
	"github.com/google/note-maps/store/query"
)

// Query returns a new query transaction based on t.
func Query(t kv.Txn) query.Txn {
	return query.Txn{models.New(t)}
}

// Command returns a new command transaction based on t.
func Command(t kv.Txn) command.Txn {
	return command.Txn{models.New(t)}
}
