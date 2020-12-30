#!/usr/bin/env bash

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

pubspec2nix() {
  local pubspec_in="$1";
  local nix_out="$2";
  if [ -z "$pubspec_in" ] || [ -z "$nix_out" ]; then
    echo "usage: dart2nix <pubspec.lock> <packages.nix>" >&2
    exit 1
  fi
  local url_template='https://storage.googleapis.com/pub-packages/packages/{{description.name}}-{{version}}.tar.gz'
  local grep_template='  { name = .{{lock.description.name}}.; version = .{{lock.version}}.; sha256 = '
  local pkg_template='  { name = "{{lock.description.name}}"; version = "{{lock.version}}"; sha256 = "{{sha256}}"; }'
  [ -f "$nix_out" ] || echo '[' > "$nix_out"
  yq -c '.packages[]' "$pubspec_in" | while read dep ; do
    match="$( echo '{"lock":'$dep'}' | mustache <(echo "$grep_template") )"
    if grep "$match" "$nix_out" ; then
      true
    else
      url="$(
        echo "$dep" \
        | mustache <(echo "$url_template")
      )"
      sha256="$(
        nix-hash --flat --base32 --type sha256 <(curl -L "$url")
      )"
      echo '{"sha256":"'$sha256'","lock":'$dep'}' | mustache <(echo "$pkg_template") >> "$nix_out"
    fi
  done
  echo ']' >> "$nix_out"
}
pubspec2nix "$@"
