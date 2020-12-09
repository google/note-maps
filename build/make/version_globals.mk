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

VERSION:
	echo $(shell git describe --tags --abbrev=0 | sed -e 's/^v//' ) > $@

VERSION_INFO:
	echo '$(shell git describe --tags --always) ($(shell git log --pretty=format:%cd --date=short -n1), $(shell git describe --tags --always --all | sed s:heads/::))' > $@

.mk.version.clean:
	rm -f VERSION VERSION_INFO

DOWNLOAD_TARGETS += VERSION VERSION_INFO
CLEAN_TARGETS    += .mk.version.clean
