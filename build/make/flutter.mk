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
# DIR := 'directory/containing/pubspec'

SRCS := $(shell find $(DIR) -name '*.dart') $(DIR)/pubspec.yaml

$(DIR)/.mk.flutter.pubgot: $(DIR)/pubspec.yaml
	cd $(DIR) ; flutter pub get
	touch $@

# FORMAT: flutter format
$(DIR)/.mk.flutter.formatted: $(SRCS)
	flutter format $?
	touch $@
FORMAT_TARGETS += $(DIR)/.mk.flutter.formatted

# LINT: flutter analyze
$(DIR)/.mk.flutter.analyzed: $(DIR)/.mk.flutter.pubgot $(SRCS)
	cd $(DIR) ; flutter analyze
	touch $@
LINT_TARGETS += $(DIR)/.mk.flutter.analyzed

# BUILD: flutter build $(FLUTTER_PLATFORMS)
$(DIR)/.mk.flutter.built.android: $(DIR)/.mk.flutter.pubgot $(SRCS)
	cd $(DIR) ; flutter build appbundle
	touch $@
$(DIR)/.mk.flutter.built.ios: $(DIR)/.mk.flutter.pubgot $(SRCS)
	cd $(DIR) ; flutter build ios
	touch $@
$(DIR)/.mk.flutter.built.macos: $(DIR)/.mk.flutter.pubgot $(SRCS)
	cd $(DIR) ; flutter build macos
	touch $@
$(DIR)/.mk.flutter.built.web: $(DIR)/.mk.flutter.pubgot $(SRCS)
	cd $(DIR) ; flutter build web
	touch $@
$(DIR)/.mk.flutter.built: $(patsubst %,$(GO_DIR)/.mk.flutter.built.%, $(FLUTTER_PLATFORMS))
BUILD_TARGETS += $(DIR)/.mk.flutter.built

$(DIR)/.mk.flutter.tested: $(DIR)/.mk.flutter.pubgot $(SRCS)
	cd $(DIR) ; flutter --no-pub test
	touch $@
TEST_TARGETS += $(DIR)/.mk.flutter.tested

.PHONY: $(DIR).mk.flutter.clean
$(DIR).mk.flutter.clean:
	cd $(DIR) ; flutter clean
CLEAN_TARGETS += $(DIR).mk.flutter.clean

.PHONY: $(DIR)/.mk.flutter.run
$(DIR)/.mk.flutter.run: $(DIR)/.mk.flutter.built
	cd $(DIR) ; flutter run --no-pub --no-build
RUN_TARGETS += $(DIR)/.mk.flutter.run
