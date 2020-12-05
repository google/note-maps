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

# Requires:
#
# DART_DIR := 'directory/containing/pubspec'

DART_SRCS := $(shell find $(DART_DIR) -name '*.dart')

$(DART_DIR)/.mk.dart.pubgot: $(DART_DIR)/pubspec.yaml
	cd $(DART_DIR) ; dart pub get
	touch $@

$(DART_DIR)/.mk.dart.analyzed: $(DART_DIR)/.mk.dart.pubgot $(DART_SRCS)
	cd $(DART_DIR) ; dart analyze
	touch $@

$(DART_DIR)/.mk.dart.formatted: $(DART_SRCS)
	dart format $?
	touch $@

$(DART_DIR)/.mk.dart.tested: $(DART_DIR)/.mk.dart.pubgot $(DART_SRCS)
	cd $(DART_DIR) ; dart test
	touch $@

FORMAT_TARGETS += $(DART_DIR)/.mk.dart.formatted
LINT_TARGETS   += $(DART_DIR)/.mk.dart.analyzed
TEST_TARGETS   += $(DART_DIR)/.mk.dart.tested
