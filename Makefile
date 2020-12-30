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

# Default configuration, can be customized on the command line or in config.mk.
#
# Example using environemnt variables:
#
#   export FLUTTER_SDK_ROOT := $(dirname $(which flutter))
#   make -e
#
# Example using the command line:
#
#   make OUTDIR="$( mktemp -d )" TMPDIR="$( mktemp -d )"
#
# Example using config.mk:
#
#   echo 'FLUTTER_BUILD := web android' >> config.mk
#   echo 'FLUTTER_SDK_ROOT := ~/flutter' >> config.mk
#   make
#
DEBUG = 1
COVERAGE = 1
OUTDIR = out
TMPDIR = tmp
FLUTTER_BUILD = web # appbundle ios linux macos windows ...?
FLUTTER_DEVICE = #web-server
FLUTTER_SDK_ROOT = $(TMPDIR)/flutter
GOMOBILE_TAGS = #android ios macos
TMPBINDIR := $(TMPDIR)/bin

# Flutter and Go use environment variables like these to decide where to write
# temporary files during precache and build phases. Nix won't let them write to
# the default $HOME. Instead, we precache to these folders in an "impure"
# precache phase so that their contents will be included as part of the source
# code during the build phase.
ifdef IN_NIX_SHELL
export HOME            = $(abspath .)
export XDG_CONFIG_HOME = $(abspath .config)
export XDG_CACHE_HOME  = $(abspath .cache)
endif

ifneq ($(realpath config.mk),)
include config.mk
endif

# Set the default target, which is the first defined target.
#
# Later, the real-all target will be defined to depend on targets defined in
# other files.
#
.PHONY: default
default: download lint test build

# Clear out the default rules:
.SUFFIXES:

$(OUTDIR):
	mkdir -p $@
$(TMPDIR):
	mkdir -p $@

# Make it easy to build temporary binaries that can be found on $PATH during
# later build steps. Required for `gomobile` to be able to find `gobind`.
export PATH := $(TMPBINDIR):$(PATH)

# Initialize variables that will accumulate names of targets defined in other
# files.
#
DOWNLOAD_TARGETS :=
FORMAT_TARGETS :=
LINT_TARGETS :=
BUILD_TARGETS :=
TEST_TARGETS :=
CLEAN_TARGETS :=

include build/make/version_globals.mk
include build/make/cc_globals.mk
include build/make/gomobile_globals.mk

include build/make/common.mk
include build/make/go.mk
include build/make/dart.mk
include build/make/flutter.mk

# TODO: resolve build problems with keychain module on OSX
#include cmd/note-maps/build.mk
include dart/nm_delta/build.mk
include dart/nm_delta_notus/build.mk
# TODO: resolve build problems with nm_gql_go_link
#include flutter/nm_gql_go_link/build.mk
include flutter/nm_app/build.mk

.PHONY: clean test real-all
download: $(OUTDIR) $(TMPDIR) $(DOWNLOAD_TARGETS)
format: $(FORMAT_TARGETS)
lint: $(LINT_TARGETS)
build: $(BUILD_TARGETS)
clean: $(CLEAN_TARGETS)
	rm -rf $(OUTDIR)
test: $(TEST_TARGETS)

.PHONY: fdroid
fdroid: $(OUTDIR)/fdroid/fdroid/repo/index.xml
$(OUTDIR)/fdroid/fdroid/repo/index.xml: $(OUTDIR)/flutter/nm_app/app/outputs/apk/release/*.apk
	mkdir -p fdroid/repo
	cp $^ fdroid/repo/
	cd fdroid ; fdroid update
	rm -rf $(OUTDIR)/fdroid
	mkdir -p $(OUTDIR)/fdroid/fdroid
	mv fdroid/repo $(OUTDIR)/fdroid/fdroid/repo
	mv fdroid/archive $(OUTDIR)/fdroid/archive
