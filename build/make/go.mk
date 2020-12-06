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

GO_PKGS := $(shell go list ./$(GO_DIR) ./$(GO_DIR)/... | grep -v vendor )
GO_SRCS := $(shell find $(GO_DIR) -name '*.go' | grep -v vendor )

$(GO_DIR)/.mk.go.formatted: $(GO_SRCS)
	go fmt ./$(GO_DIR)
	touch $@

$(GO_DIR)/.mk.go.vetted: $(GO_SRCS)
	go vet $(GO_PKGS)
	touch $@

# `go build` has its own caching built in.
$(GO_DIR)/.mk.go.built: $(GO_SRCS)
	go build $(GO_PKGS)
	touch $@

# `go test` has its own caching built in.
$(GO_DIR)/.mk.go.tested:
	go test $(GO_PKGS)
	touch $@

FORMAT_TARGETS += $(GO_DIR)/.mk.go.formatted
LINT_TARGETS   += $(GO_DIR)/.mk.go.vetted
BUILD_TARGETS  += $(GO_DIR)/.mk.go.built
TEST_TARGETS   += $(GO_DIR)/.mk.go.tested

#undefine GO_PKGS
#undefine GO_SRCS
