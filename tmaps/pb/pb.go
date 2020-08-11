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

// Package pb defines protocol buffer message types intended for use in tmaps
// APIs.
//
// These message types are different and independent from those used in
// storage.
package pb

//go:generate protoc --go_out=paths=source_relative:. pb.proto

//go:generate protoc --dart_out=../../note_maps/lib/mobileapi/store/pb pb.proto
