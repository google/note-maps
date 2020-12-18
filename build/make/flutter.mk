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

FLUTTER = flutter
FLUTTER_VERSION = 1.24.0-6.0.pre
FLUTTER_INSTALLED = $(shell which "$(FLUTTER)")

ifeq ($(FLUTTER_INSTALLED),)
.mk.flutter.download:
	[ -x "$(TMPDIR)/flutter" ] || git clone -b $(FLUTTER_VERSION) --depth 1 https://github.com/flutter/flutter.git $(TMPDIR)/flutter
DOWNLOAD_TARGETS += .mk.flutter.download
FLUTTER = $(TMPDIR)/flutter/bin/flutter
DART = $(TMPDIR)/flutter/bin/dart
endif

ifdef DEBUG
FLUTTER_BUILD_FLAGS += --debug
else
FLUTTER_BUILD_FLAGS += --release
endif

.mk.flutter.config: $(patsubst %,.mk.flutter.config.%,$(FLUTTER_BUILD))
.mk.flutter.config.linux: ; $(FLUTTER) config --enable-linux-desktop && touch $@
.mk.flutter.config.macos: ; $(FLUTTER) config --enable-macos-desktop && touch $@
.mk.flutter.config.windows: ; $(FLUTTER) config --enable-windows-desktop && touch $@
.mk.flutter.config.%: ; @touch $@

flutter_find_srcs = $(shell find $(1) -name '*.dart')

define flutter_pub_get =
	cd $(dir $@) && $(FLUTTER) pub get
	touch $@
endef

define flutter_format =
	$(FLUTTER) format $?
	touch $@
endef

define flutter_lint =
	@echo disabling flutter analyze for now # cd $(dir $@) && $(FLUTTER) analyze
	touch $@
endef

define flutter_build =
	cd $(dir $@) ; $(FLUTTER) build $(subst .,,$(suffix $@)) $(FLUTTER_BUILD_FLAGS)
	mkdir -p $(OUTDIR)/$(dir $@)
	mv $(dir $@)/build/app/outputs/* $(OUTDIR)/$(dir $@)
endef

define flutter_test =
	cd $(dir $@) && $(FLUTTER) test
	touch $@
endef
