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

$(FLUTTER_NM_APP)/.mk.flutter.build.%: .mk.flutter.config.% $(FLUTTER_NM_APP)/.mk.flutter.pub.get $(FLUTTER_NM_APP)/.mk.flutter.analyze $(FLUTTER_NM_APP_SRCS)
	$(call flutter_build)

$(FLUTTER_NM_APP)/.mk.flutter.test: $(FLUTTER_NM_APP)/.mk.flutter.pub.get $(FLUTTER_NM_APP_SRCS)
	$(call flutter_test $(1))

.PHONY: $(FLUTTER_NM_APP)/.mk.flutter.clean
$(FLUTTER_NM_APP)/.mk.flutter.clean:
	cd $(FLUTTER_NM_APP) ; $(FLUTTER) clean
	rm -f $(FLUTTER_NM_APP)/.mk.*

DOWNLOAD_TARGETS += $(FLUTTER_NM_APP)/.mk.flutter.pub.get
FORMAT_TARGETS += $(FLUTTER_NM_APP)/.mk.flutter.format
# TODO: re-enable linting in nm_app
#LINT_TARGETS += $(FLUTTER_NM_APP)/.mk.flutter.analyze
BUILD_TARGETS += $(patsubst %,$(FLUTTER_NM_APP)/.mk.flutter.build.%,$(FLUTTER_BUILD))
TEST_TARGETS += $(FLUTTER_NM_APP)/.mk.flutter.test
CLEAN_TARGETS += $(FLUTTER_NM_APP)/.mk.flutter.clean
