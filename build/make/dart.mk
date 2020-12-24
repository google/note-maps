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

DART = dart

ifdef NO_HOME
export PUB_CACHE=$(abspath $(TMPDIR)/pub-cache)
else
# Flutter as wrapped for Nix sometimes tries to write to a read-only path. This
# is a work-around to make it write to the default Linux/OSX location.
export PUB_CACHE=$(abspath $(HOME)/.pub-cache)
endif

dart_find_srcs = $(shell find $(1) -name '*.dart') $(1)/pubspec.yaml

define dart_pub_get =
	cd $(dir $@) ; $(DART) pub get
	touch $@
endef

define dart_format =
	cd $(dir $@) ; $(DART) format $?
	touch $@
endef

define dart_lint =
	@echo disabling $(DART) analyze for now # cd $(dir $@) ; $(DART) analyze
	touch $@
endef

define dart_test =
	cd $(dir $@) ; $(DART) test
	touch $@
endef
