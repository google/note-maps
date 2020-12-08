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

dart_find_srcs = $(shell find $(1) -name '*.dart') $(1)/pubspec.yaml
define dart_pub_get =
	cd $(dir $@) ; dart pub get
	touch $@
endef

define dart_format =
	cd $(dir $@) ; dart format $?
	touch $@
endef

define dart_lint =
	echo disabling dart analyze for now # cd $(dir $@) ; dart analyze
	touch $@
endef

define dart_test =
	cd $(dir $@) ; dart test
	touch $@
endef
