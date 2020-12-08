# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

go_pkgs = $(shell go list ./$($(1))/... | grep -v 'vendor\|tmp' )
go_srcs = $(shell find ./$($(1)) -name '*.go' | grep -v 'vendor\|tmp' )

define go_fmt =
	go fmt ./$(dir $@)...
	touch $@
endef

define go_vet =
	go vet ./$(dir $@)...
	touch $@
endef

define go_build =
	go install ./$(dir $@)...
	touch $@
endef

define go_test =
	go test ./$(dir $@)...
	touch $@
endef

.mk.go.download: go.mod go.sum
	[ -z "$(shell go env GOTMPDIR)" ] || mkdir -p "$(shell go env GOTMPDIR)"
	go mod download
	touch $@

DOWNLOAD_TARGETS += .mk.go.download
