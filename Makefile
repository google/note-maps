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

# Default configuration, can be customized on the command line.
#
# Example:
#
#   make OUTDIR="$( mktemp -d )" TMPDIR="$( mktemp -d )"
#
DEBUG = 1
COVERAGE = 1
CC = clang
OUTDIR = $(PWD)/out
TMPDIR = $(PWD)/tmp
FLUTTER_BUILD = appbundle
FLUTTER_DEVICE = web-server
GOMOBILE_TAGS = android ios macos
TMPBINDIR := $(TMPDIR)/bin

# Make it easy to build temporary binaries that can be found on $PATH during
# later build steps. Required for `gomobile` to be able to find `gobind`.
export PATH := $(TMPBINDIR):$(PATH)

# Set the default target, which is the first defined target.
#
# Later, the real-all target will be defined to depend on targets defined in
# other files.
#
.PHONY: default
default: build

# Initialize variables that will accumulate names of targets defined in other
# files.
#
FORMAT_TARGETS :=
LINT_TARGETS :=
BUILD_TARGETS :=
TEST_TARGETS :=
CLEAN_TARGETS :=
RUN_TARGETS :=

include build/make/version_globals.mk
include build/make/cc_globals.mk
include build/make/gomobile_globals.mk

include build/make/common.mk
include build/make/go.mk
include build/make/dart.mk
include build/make/flutter.mk

include cmd/note-maps/build.mk
include dart/nm_delta/build.mk
include dart/nm_delta_notus/build.mk
# TODO: resolve build problems with nm_gql_go_link
#include flutter/nm_gql_go_link/build.mk
include flutter/nm_app/build.mk

.PHONY: clean test real-all
format: $(FORMAT_TARGETS)
lint: $(LINT_TARGETS)
build: $(BUILD_TARGETS)
clean: $(CLEAN_TARGETS)
test: $(TEST_TARGETS)
run: $(RUN_TARGETS)
