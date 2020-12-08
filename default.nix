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

{ project ? import ./nix { }
, pkgs ? project.pkgs
, bash ? pkgs.bash
, lib ? pkgs.lib
, stdenv ? pkgs.stdenv
}:
stdenv.mkDerivation {
  name = "note_maps-0.1.0";
  src = builtins.path { path = ./.; name = "note_maps"; };
  nativeBuildInputs = builtins.attrValues project.runtimeDeps;
  buildInputs = builtins.attrValues project.ciTools ++ lib.optionals (stdenv.buildPlatform.isLinux) project.linuxBuildTools;
  builder = "${bash}/bin/bash";
  args = [ ./nix/build.sh ];
}
