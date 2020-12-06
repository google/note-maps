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

.PHONY: ios-plugin android-plugin

GO_DIR := flutter/nm_gql_go_link

include build/make/go.mk

$(GO_DIR)/.mk.go.generate.ios: .gomobile $(GO_DIR)/.mk.go.built
	go generate -tags ios ./$(GO_DIR)

$(GO_DIR)/.mk.go.generate.android: .gomobile $(GO_DIR)/.mk.go.built
	go generate -tags android ./$(GO_DIR)

$(GO_DIR)/.mk.go.generate.macos: .gomobile $(GO_DIR)/.mk.go.built
	go generate -tags macos ./$(GO_DIR)

BUILD_TARGETS += $(patsubst %,$(GO_DIR)/.mk.go.generate.%, $(FLUTTER_PLATFORMS))
