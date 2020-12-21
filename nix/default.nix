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
  config = { android_sdk.accept_license = true; };

  # Some packages from unstable need the fix in
  # https://github.com/NixOS/nixpkgs/pull/106830
  unstable_patched =
    import sources.unstable-fix-autopatchelfhook {
      inherit config;
    };
  unstable_patched_overlay = _: pkgs: { inherit (unstable_patched) androidenv; };
  unstable = import sources.unstable {
    inherit config;
  };
  unstable_overlay = _: pkgs: { inherit (unstable) jdk; };

  flutter_overlay = _: pkgs: rec {
    flutterPackages =
      unstable.callPackage
      ../third_party/github.com/NixOS/nixpkgs/development/compilers/flutter {
        inherit (unstable) callPackage dart lib stdenv ;
      };
    flutter-dev = flutterPackages.dev;
  };

  pkgs = import sources.nixpkgs {
    inherit config;
    overlays = [
      unstable_patched_overlay
      unstable_overlay
      flutter_overlay
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
    inherit (pkgs) flutter-dev git go gnumake jdk;
    inherit androidsdk;
  } // lib.optionalAttrs(stdenv.isLinux) {
    inherit (pkgs) clang cmake ninja;
  } // lib.optionalAttrs(stdenv.isDarwin) {
    inherit (pkgs) clang;
  };

  # Additional tools required to build Note Maps in a more controlled
  # environment.
  ciTools = buildTools // {
    inherit (pkgs) coreutils findutils moreutils;
    inherit (pkgs) git gnugrep gnused;
  };

  # Additional tools useful for code work and repository maintenance.
  devTools = runtimeDeps // buildTools // {
    inherit (pkgs) niv;
  };

  nativeBuildInputs = builtins.attrValues runtimeDeps;
  buildInputs = builtins.attrValues ciTools;
  shellInputs = builtins.attrValues devTools;
  shellHook = ''
    export ANDROID_HOME="${androidsdk}/libexec/android-sdk"
    export JAVA_HOME="${pkgs.jdk}"
  '';
}
