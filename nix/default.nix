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
  config = {
    #allowUnfree = true; # for android-studio
    android_sdk.accept_license = true;
  };
  unstable = import sources.unstable {
    inherit config;
    overlays = [ (
      _: pkgs: rec {
          flutterPackages =
            pkgs.callPackage
            ../third_party/github.com/NixOS/nixpkgs/development/compilers/flutter {
              inherit (pkgs) callPackage dart lib stdenv ;
            };
          flutter-dev = flutterPackages.dev;
        } ) ];
  };
  pkgs = import sources.nixpkgs {
    inherit config;
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
  androidsdk = (pkgs.androidenv.composeAndroidPackages {
    buildToolsVersions = [ "28.0.3" ];
    platformVersions = [ "29" ];
    platformToolsVersion = "29.0.6";
    includeNDK = true;
    ndkVersion = "21.0.6113669";
    abiVersions = [ "x86-64" ];
  }).androidsdk;
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
    inherit (androidComposition) androidsdk;
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
