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

ifdef DEBUG
CFLAGS ?= -g
else
CFLAGS ?= -O3
endif

NM_CFLAGS  = $(CFLAGS) -std=c11
NM_CFLAGS += -Wall
NM_CFLAGS += -Wpedantic
NM_CFLAGS += -Werror
NM_CFLAGS += -Iinclude

NM_CPPFLAGS  = -DNM_VERSION=\"${NM_VERSION}\"
NM_CPPFLAGS += -DMAJOR_VERSION=${MAJOR_VERSION}
NM_CPPFLAGS += -DMINOR_VERSION=${MINOR_VERSION}
NM_CPPFLAGS += -DPATCH_VERSION=${PATCH_VERSION}

NM_LIBS = -Llib
