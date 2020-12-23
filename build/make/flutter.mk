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

FLUTTER_VERSION = 1.23.0-7.0.pre
FLUTTER = "$(FLUTTER_SDK_ROOT)/bin/flutter"
DART = "$(FLUTTER_SDK_ROOT)/bin/dart"

https://github.com/flutter/flutter/archive/1.26.0-1.0.pre.tar.gz

$(FLUTTER_SDK_ROOT):
	git clone https://github.com/flutter/flutter.git $(FLUTTER_SDK_ROOT)

.PHONY: .mk.flutter.download
.mk.flutter.download: $(FLUTTER_SDK_ROOT)
	@echo '*** Using flutter $(FLUTTER_VERSION) ...'
ifneq ($(shell cd "$(FLUTTER_SDK_ROOT)" ; git describe --tags),$(FLUTTER_VERSION))
	cd "$(FLUTTER_SDK_ROOT)" ; git checkout $(FLUTTER_VERSION) || ( git fetch && git checkout $(FLUTTER_VERSION) )
endif
	"$(FLUTTER)" precache
ifneq ($(shell which flutter),$(FLUTTER))
	@echo '*** Using:'
	@echo '***   flutter at $(FLUTTER)'
	@echo '***   dart at $(DART)'
	@echo '*** To use the same versions outside of make, either:'
	@echo '***   export PATH=$$PATH:$(FLUTTER_SDK_ROOT)/bin'
	@echo '*** or'
	@echo '***   alias flutter=$(FLUTTER)'
	@echo '***   alias dart=$(DART)'
endif
DOWNLOAD_TARGETS += .mk.flutter.download

.mk.flutter.config: $(patsubst %,.mk.flutter.config.%,$(FLUTTER_BUILD))
.mk.flutter.config.linux: ; $(FLUTTER) config --enable-linux-desktop && touch $@
.mk.flutter.config.macos: ; $(FLUTTER) config --enable-macos-desktop && touch $@
.mk.flutter.config.windows: ; $(FLUTTER) config --enable-windows-desktop && touch $@
.mk.flutter.config.web: ; $(FLUTTER) config --enable-web && touch $@
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


ifneq ($(DEBUG),)
.mk.flutter.debug = \
	$(if $(findstring $(1),apk appbundle ios),--debug) \
	$(if $(findstring $(1),web),--profile)
else
.mk.flutter.debug =
endif

.mk.flutter.build = build $(1) \
	$(call .mk.flutter.debug,$(1)) \
	$(if $(findstring $(1),apk),--split-per-abi)

define flutter_build =
	cd $(dir $@) ; $(FLUTTER) $(call .mk.flutter.build,$(subst .,,$(suffix $@)))
	mkdir -p $(OUTDIR)/$(dir $@)
	rm -rf $(subst $(dir $@)/build/,$(OUTDIR)/$(dir $@),$(wildcard $(dir $@)/build/*))
	cp -r $(dir $@)build/* $(OUTDIR)/$(dir $@)
endef

define flutter_test =
	cd $(dir $@) && $(FLUTTER) test
	touch $@
endef
