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
# FLUTTER_DIR := 'directory/containing/pubspec'

FLUTTER_SRCS := $(shell find $(FLUTTER_DIR) -name '*.dart') $(FLUTTER_DIR)/pubspec.yaml

$(FLUTTER_DIR)/.mk.flutter.pubgot: $(FLUTTER_DIR)/pubspec.yaml
	cd $(FLUTTER_DIR) ; flutter pub get
	touch $@

# FORMAT: flutter format
$(FLUTTER_DIR)/.mk.flutter.formatted: $(FLUTTER_SRCS)
	flutter format $?
	touch $@
FORMAT_TARGETS += $(FLUTTER_DIR)/.mk.flutter.formatted

# LINT: flutter analyze
$(FLUTTER_DIR)/.mk.flutter.analyzed: $(FLUTTER_DIR)/.mk.flutter.pubgot $(FLUTTER_SRCS)
	cd $(FLUTTER_DIR) ; flutter analyze
	touch $@
LINT_TARGETS += $(FLUTTER_DIR)/.mk.flutter.analyzed

# BUILD: flutter build $(FLUTTER_PLATFORMS)
$(FLUTTER_DIR)/.mk.flutter.built.android: $(FLUTTER_DIR)/.mk.flutter.pubgot $(FLUTTER_SRCS)
	cd $(FLUTTER_DIR) ; flutter build appbundle
	touch $@
$(FLUTTER_DIR)/.mk.flutter.built.ios: $(FLUTTER_DIR)/.mk.flutter.pubgot $(FLUTTER_SRCS)
	cd $(FLUTTER_DIR) ; flutter build ios
	touch $@
$(FLUTTER_DIR)/.mk.flutter.built.macos: $(FLUTTER_DIR)/.mk.flutter.pubgot $(FLUTTER_SRCS)
	cd $(FLUTTER_DIR) ; flutter build macos
	touch $@
$(FLUTTER_DIR)/.mk.flutter.built.web: $(FLUTTER_DIR)/.mk.flutter.pubgot $(FLUTTER_SRCS)
	cd $(FLUTTER_DIR) ; flutter build web
	touch $@
$(FLUTTER_DIR)/.mk.flutter.built: $(patsubst %,$(GO_DIR)/.mk.flutter.built.%, $(FLUTTER_PLATFORMS))
BUILD_TARGETS += $(FLUTTER_DIR)/.mk.flutter.built

$(FLUTTER_DIR)/.mk.flutter.tested: $(FLUTTER_DIR)/.mk.flutter.pubgot $(FLUTTER_SRCS)
	cd $(FLUTTER_DIR) ; flutter --no-pub test
	touch $@
TEST_TARGETS += $(FLUTTER_DIR)/.mk.flutter.tested

.PHONY: $(FLUTTER_DIR).mk.flutter.clean
$(FLUTTER_DIR).mk.flutter.clean:
	cd $(FLUTTER_DIR) ; flutter clean
CLEAN_TARGETS += $(FLUTTER_DIR).mk.flutter.clean

.PHONY: $(FLUTTER_DIR)/.mk.flutter.run
$(FLUTTER_DIR)/.mk.flutter.run: $(FLUTTER_DIR)/.mk.flutter.built
	cd $(FLUTTER_DIR) ; flutter run --no-pub --no-build
RUN_TARGETS += $(FLUTTER_DIR)/.mk.flutter.run
