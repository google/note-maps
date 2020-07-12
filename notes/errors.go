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

// Package notes provides types and functions for interacting with a note maps
// data storage system.
package notes

import "strconv"

type Error int

const (
	InvalidId Error = iota
)

func (e Error) Error() string {
	switch e {
	case InvalidId:
		return "invalid note id"
	default:
		return "unknown note maps error code " +
			strconv.FormatInt(int64(e), 10)
	}
}
