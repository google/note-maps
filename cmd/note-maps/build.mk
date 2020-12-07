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

CMD_NOTE_MAPS := cmd/note-maps

CMD_NOTE_MAPS_SRCS := $(call go_srcs CMD_NOTE_MAPS)

$(CMD_NOTE_MAPS)/.mk.go.format: $(CMD_NOTE_MAPS_SRCS)
	$(call go_fmt $(CMD_NOTE_MAPS))

$(CMD_NOTE_MAPS)/.mk.go.vet: $(CMD_NOTE_MAPS_SRCS)
	$(call go_vet $(CMD_NOTE_MAPS))

# `go build` has its own caching built in.
$(CMD_NOTE_MAPS)/.mk.go.build: $(CMD_NOTE_MAPS_SRCS)
	echo CMD_NOTE_MAPS=$(CMD_NOTE_MAPS)
	$(call go_build $(CMD_NOTE_MAPS))

# `go test` has its own caching built in.
$(CMD_NOTE_MAPS)/.mk.go.test:
	$(call go_test $(CMD_NOTE_MAPS))

$(CMD_NOTE_MAPS)/.mk.go.clean:
	$(call common_clean)

FORMAT_TARGETS += $(CMD_NOTE_MAPS)/.mk.go.format
LINT_TARGETS   += $(CMD_NOTE_MAPS)/.mk.go.vet
BUILD_TARGETS  += $(CMD_NOTE_MAPS)/.mk.go.build
TEST_TARGETS   += $(CMD_NOTE_MAPS)/.mk.go.test
CLEAN_TARGETS  += $(CMD_NOTE_MAPS)/.mk.go.clean
