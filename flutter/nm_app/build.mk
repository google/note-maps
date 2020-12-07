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

FLUTTER_NM_APP := flutter/nm_app
FLUTTER_NM_APP_SRCS := $(call flutter_find_srcs,$(FLUTTER_NM_APP))

$(FLUTTER_NM_APP)/.mk.flutter.pub.get: $(FLUTTER_NM_APP)/pubspec.yaml
	$(call flutter_pub_get $(FLUTTER_NM_APP))

$(FLUTTER_NM_APP)/.mk.flutter.format: $(FLUTTER_NM_APP_SRCS)
	$(call flutter_format $(FLUTTER_NM_APP))

$(FLUTTER_NM_APP)/.mk.flutter.analyze: $(FLUTTER_NM_APP)/.mk.flutter.pub.get $(FLUTTER_NM_APP_SRCS)
	$(call flutter_lint $(FLUTTER_NM_APP))

$(FLUTTER_NM_APP)/.mk.flutter.build.appbundle: $(FLUTTER_NM_APP)/.mk.flutter.pub.get $(FLUTTER_NM_APP_SRCS)
	$(call flutter_build $(FLUTTER_NM_APP) appbundle)

$(FLUTTER_NM_APP)/.mk.flutter.build.ios: $(FLUTTER_NM_APP)/.mk.flutter.pub.get $(FLUTTER_NM_APP_SRCS)
	$(call flutter_build $(FLUTTER_NM_APP) ios)

$(FLUTTER_NM_APP)/.mk.flutter.build.macos: $(FLUTTER_NM_APP)/.mk.flutter.pub.get $(FLUTTER_NM_APP_SRCS)
	$(call flutter_build $(FLUTTER_NM_APP) macos)

$(FLUTTER_NM_APP)/.mk.flutter.build.bundle: $(FLUTTER_NM_APP)/.mk.flutter.pub.get $(FLUTTER_NM_APP_SRCS)
	$(call flutter_build $(FLUTTER_NM_APP) bundle)

$(FLUTTER_NM_APP)/.mk.flutter.build: $(DART_NM_DELTA)/.mk.dart.analyze $(DART_NM_DELTA_NOTUS)/.mk.dart.analyze $(FLUTTER_NM_APP)/.mk.flutter.analyze $(patsubst %,$(FLUTTER_NM_APP)/.mk.flutter.build.%, $(FLUTTER_BUILD))

$(FLUTTER_NM_APP)/.mk.flutter.test: $(FLUTTER_NM_APP)/.mk.flutter.pub.get $(FLUTTER_NM_APP_SRCS)
	$(call flutter_test $(1))

.PHONY: $(FLUTTER_NM_APP)/.mk.flutter.clean
$(FLUTTER_NM_APP)/.mk.flutter.clean:
	cd $(FLUTTER_NM_APP) ; flutter clean

.PHONY: $(FLUTTER_NM_APP)/.mk.flutter.run
$(FLUTTER_NM_APP)/.mk.flutter.run: $(FLUTTER_NM_APP)/.mk.flutter.build
	cd $(FLUTTER_NM_APP) ; flutter run --no-pub --no-build $(FLUTTER_DEVICE)

FORMAT_TARGETS += $(FLUTTER_NM_APP)/.mk.flutter.format
LINT_TARGETS += $(FLUTTER_NM_APP)/.mk.flutter.analyze
BUILD_TARGETS += $(FLUTTER_NM_APP)/.mk.flutter.build
TEST_TARGETS += $(FLUTTER_NM_APP)/.mk.flutter.test
CLEAN_TARGETS += $(FLUTTER_NM_APP)/.mk.flutter.clean
RUN_TARGETS += $(FLUTTER_NM_APP)/.mk.flutter.run
