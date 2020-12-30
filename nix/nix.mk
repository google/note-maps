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
	@echo "  make -f nix/nix.mk precache  # once after any significant change"
	@echo "  make -f nix/nix.mk appbundle"
	@echo "  make -f nix/nix.mk ios"
	@echo "  make -f nix/nix.mk web"
	@echo "  make -f nix/nix.mk clean precache appbundle ios web"

precache:
	HOME=$(abspath .) XDG_CACHE_HOME=$(abspath .cache) nix-shell --run "flutter precache"
	touch $@

web:       .precache.mk ; nix-build -A app.$@ -o $@
appbundle: .precache.mk ; nix-build -A app.$@ -o $@
ios:       .precache.mk ; nix-build -A app.$@ -o $@

.PHONY:
clean:
	rm -f .*.mk
