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

# This Makefile file is intended to be used from the root of the repository.
#
# Example:
#
#   make -f nix/nix.mk clean web appbundle ios
#

.PHONY:
default:
	@echo "Usage:"
	@echo "  make -f nix/nix.mk precache  # after each significant change"
	@echo "  make -f nix/nix.mk app.apk"
	@echo "  make -f nix/nix.mk app.appbundle"
	@echo "  make -f nix/nix.mk app.ios"
	@echo "  make -f nix/nix.mk app.linux"
	@echo "  make -f nix/nix.mk app.macos"
	@echo "  make -f nix/nix.mk app.web"
	@echo "  make -f nix/nix.mk clean precache app.web"

all: clean precache apk appbundle ios linux macos web

precache: .precache.mk
.precache.mk:
	export HOME=$(abspath .) XDG_CACHE_HOME=$(abspath .cache) ; nix-shell --run "flutter precache"
	touch $@

apk:       ; nix-build -A app.$@ -o $@
appbundle: ; nix-build -A app.$@ -o $@
ios:       ; nix-build -A app.$@ -o $@
linux:     ; nix-build -A app.$@ -o $@
macos:     ; nix-build -A app.$@ -o $@
web:       ; nix-build -A app.$@ -o $@

.PHONY:
clean:
	rm -f .*.mk apk appbundle ios linux macos web
