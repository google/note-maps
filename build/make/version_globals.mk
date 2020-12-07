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

VERSION := $(shell git describe --tags --abbrev=0 | sed -e 's/^v//' )

MAJOR_VERSION := $(shell echo ${VERSION} | cut -d '.' -f 1)
MINOR_VERSION := $(shell echo ${VERSION} | cut -d '.' -f 2)
PATCH_VERSION := $(shell echo ${VERSION} | cut -d '.' -f 3)
ifeq (${PATCH_VERSION},)
PATCH_VERSION := 0
endif

VERSION_INFO := '$(shell git describe --tags --always) ($(shell git log --pretty=format:%cd --date=short -n1), branch \"$(shell git describe --tags --always --all | sed s:heads/::)\")'
