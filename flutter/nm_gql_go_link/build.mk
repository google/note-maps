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

FLUTTER_NM_GQL_GO_LINK := flutter/nm_gql_go_link
FLUTTER_NM_GQL_GO_LINK_SRCS := $(call flutter_find_srcs,$(FLUTTER_NM_GQL_GO_LINK))

gomobile = $(shell go generate -tags $(2) ./$(1))

$(FLUTTER_NM_GQL_GO_LINK)/.mk.flutter.pub.get: $(FLUTTER_NM_GQL_GO_LINK)/pubspec.yaml
	$(call flutter_pub_get $(FLUTTER_NM_GQL_GO_LINK))

$(FLUTTER_NM_GQL_GO_LINK)/.mk.flutter.format: $(FLUTTER_NM_GQL_GO_LINK)/.mk.flutter.pub.get $(FLUTTER_NM_GQL_GO_LINK_SRCS)
	$(call flutter_format $(FLUTTER_NM_GQL_GO_LINK))

$(FLUTTER_NM_GQL_GO_LINK)/.mk.flutter.analyze: $(FLUTTER_NM_GQL_GO_LINK)/.mk.flutter.pub.get $(FLUTTER_NM_GQL_GO_LINK_SRCS)
	$(call flutter_lint $(FLUTTER_NM_GQL_GO_LINK))

$(FLUTTER_NM_GQL_GO_LINK)/.mk.go.generate.ios: $(GOMOBILE) $(GOBIND)
	$(call gomobile $(FLUTTER_NM_GQL_GO_LINK) ios)
$(FLUTTER_NM_GQL_GO_LINK)/.mk.go.generate.android: $(GOMOBILE) $(GOBIND)
	$(call gomobile $(FLUTTER_NM_GQL_GO_LINK) android)
$(FLUTTER_NM_GQL_GO_LINK)/.mk.go.generate.macos: $(GOMOBILE) $(GOBIND)
	$(call gomobile $(FLUTTER_NM_GQL_GO_LINK) macos)
$(FLUTTER_NM_GQL_GO_LINK)/.mk.flutter.build: $(patsubst %,$(FLUTTER_NM_GQL_GO_LINK)/.mk.go.generate.%, $(FLUTTER_PLATFORMS))

$(FLUTTER_NM_GQL_GO_LINK)/.mk.flutter.test: $(FLUTTER_NM_GQL_GO_LINK)/.mk.flutter.pub.get $(FLUTTER_NM_GQL_GO_LINK_SRCS)
	$(call flutter_test $(1))

.PHONY: $(FLUTTER_NM_GQL_GO_LINK)/.mk.flutter.clean
$(FLUTTER_NM_GQL_GO_LINK)/.mk.flutter.clean:
	cd $(FLUTTER_NM_GQL_GO_LINK) ; flutter clean

FORMAT_TARGETS += $(FLUTTER_NM_GQL_GO_LINK)/.mk.flutter.format
LINT_TARGETS += $(FLUTTER_NM_GQL_GO_LINK)/.mk.flutter.analyze
BUILD_TARGETS += $(FLUTTER_NM_GQL_GO_LINK)/.mk.flutter.build
TEST_TARGETS += $(FLUTTER_NM_GQL_GO_LINK)/.mk.flutter.test
CLEAN_TARGETS += $(FLUTTER_NM_GQL_GO_LINK).mk.flutter.clean
