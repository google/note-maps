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

DART_NM_DELTA := dart/nm_delta
DART_NM_DELTA_SRCS := $(shell find $(DART_NM_DELTA) -name '*.dart')

$(DART_NM_DELTA)/.mk.dart.pub.get: $(DART_NM_DELTA)/pubspec.yaml
	$(call dart_pub_get)

$(DART_NM_DELTA)/.mk.dart.analyze: $(DART_NM_DELTA)/.mk.dart.pub.get $(DART_NM_DELTA_SRCS)
	$(call dart_lint)

$(DART_NM_DELTA)/.mk.dart.format: $(DART_NM_DELTA_SRCS)
	$(call dart_format)

$(DART_NM_DELTA)/.mk.dart.test: $(DART_NM_DELTA)/.mk.dart.pub.get $(DART_NM_DELTA_SRCS)
	$(call dart_test)

.PHONY: $(DART_NM_DELTA)/.mk.dart.clean
$(DART_NM_DELTA)/.mk.dart.clean:
	$(call common_clean)

FORMAT_TARGETS += $(DART_NM_DELTA)/.mk.dart.format
LINT_TARGETS   += $(DART_NM_DELTA)/.mk.dart.analyze
TEST_TARGETS   += $(DART_NM_DELTA)/.mk.dart.test
CLEAN_TARGETS  += $(DART_NM_DELTA)/.mk.dart.clean
