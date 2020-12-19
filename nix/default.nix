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

{ sources ? import ./sources.nix
}:
let
  unstable = import sources.unstable {
    overlays = [ (
      _: pkgs: rec
        { flutterPackages = ( pkgs.callPackage ../third_party/github.com/NixOS/nixpkgs/development/compilers/flutter
            { inherit (pkgs) callPackage
            ; inherit (pkgs) dart
            ; inherit (pkgs) stdenv
            ; inherit (pkgs) lib
            ; } )
        ; flutter-dev = flutterPackages.dev; } ) ];
  };
  pkgs = import sources.nixpkgs {
    overlays = [
      (_: pkgs:
	{ inherit (unstable) flutter-dev;
	})
    ];
  };
  gitignoreSource = (import sources."gitignore.nix" { inherit (pkgs) lib; }).gitignoreSource;
  src = gitignoreSource ./..;
  lib = pkgs.lib;
  stdenv = pkgs.stdenv;
in rec
{
  inherit pkgs src;

  # Runtime dependencies.
  runtimeDeps = {
  };

  # Minimum tools required to build Note Maps.
  buildTools = {
    inherit (pkgs) clang;
    inherit (pkgs) flutter-dev;
    inherit (pkgs) git; # required by flutter!
    inherit (pkgs) gnumake;
    inherit (pkgs) go;
  };

  # Additional tools required to build Note Maps in a more controlled
  # environment.
  ciTools = buildTools // {
    inherit (pkgs) coreutils;
    inherit (pkgs) findutils;
    inherit (pkgs) moreutils;
    inherit (pkgs) git;
    inherit (pkgs) gnugrep;
    inherit (pkgs) gnused;
  };

  # Additional tools useful for code work and repository maintenance.
  devTools = runtimeDeps // buildTools // {
    inherit (pkgs) niv;
  };

  nativeBuildInputs = builtins.attrValues runtimeDeps;
  buildInputs = builtins.attrValues ciTools;
  shellInputs = builtins.attrValues devTools;
}
