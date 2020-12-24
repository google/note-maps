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

go_pkgs = $(shell go list ./$($(1))/... | grep -v 'vendor\|tmp' )
go_srcs = $(shell find ./$($(1)) -name '*.go' | grep -v 'vendor\|tmp' )

# Export some variables to the environment
ifdef NO_HOME
export GOTMPDIR=$(abspath $(TMPDIR)/gotmp)
export GOCACHE=$(abspath $(TMPDIR)/gocache)
export GOMODCACHE=$(abspath $(TMPDIR)/gomodcache)
endif

define go_dirs =
	[ -d "$$GOTMPDIR" ] || mkdir -p "$$GOTMPDIR"
	[ -d "$$GOCACHE" ] || mkdir -p "$$GOCACHE"
	[ -d "$$GOMODCACHE" ] || mkdir -p "$$GOMODCACHE"
endef

define go_fmt =
	$(call go_dirs)
	go fmt ./$(dir $@)...
	touch $@
endef

define go_vet =
	$(call go_dirs)
	go vet ./$(dir $@)...
	touch $@
endef

define go_build =
	$(call go_dirs)
	mkdir -p "$$GOTMPDIR"
	go env
	go build -o "$(TMPDIR)/bin/$(shell basename $(shell go list ./$(dir $@)))" ./$(dir $@)
	mkdir -p "$(OUTDIR)/bin"
	mv "$(TMPDIR)/bin/$(shell basename $(shell go list ./$(dir $@)))" "$(OUTDIR)/bin/"
	touch $@
endef

define go_test =
	$(call go_dirs)
	go test ./$(dir $@)...
	touch $@
endef

$(GOTMPDIR):
	mkdir -p $@

.mk.go.download: $(GOTMPDIR) go.mod go.sum
	$(call go_dirs)
	go mod download
	touch $@

DOWNLOAD_TARGETS += .mk.go.download
