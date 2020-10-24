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

// +build macos

package nmgql

// `go:generate` directives for MacOS
//
// Usage: go generate -tags macos
//
// Note: These commands only produce correct outputs when the build
// environement is OSX (this should be fine since OSX is the only supported
// build environment for OSX applications anyway.)

//go:generate gobind -lang=go,objc -outdir=./tmp/macos/ -tags=macos -prefix=Go github.com/google/note-maps/flutter/nm_gql_go_link
//go:generate go build -tags macos -v -x -work -buildmode=c-archive -o ./tmp/macos/GoNmgql-amd64.a ./tmp/macos/src/gobind
//go:generate mkdir -p ./macos/Frameworks/GoNmgql.framework/Versions/A/Headers
//go:generate xcrun lipo -create -arch x86_64 ./tmp/macos/GoNmgql-amd64.a -o ./macos/Frameworks/GoNmgql.framework/Versions/A/GoNmgql
//go:generate cp tmp/macos/src/gobind/GoNmgql.objc.h tmp/macos/src/gobind/Universe.objc.h tmp/macos/src/gobind/ref.h macos/Frameworks/GoNmgql.framework/Versions/A/Headers
