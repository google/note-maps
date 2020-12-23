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
  make-extra-builtins = import sources.nix-fetchers."make-extra-builtins.nix" {};
  extra-builtins = make-extra-builtins { fetchers = import sources.nix-fetchers."extra-builtins.nix" {}; };
  exec' = builtins.exec or
    (throw "Tests require the allow-unsafe-native-code-during-evaluation Nix setting to be true");
  all-fetchers = import "${extra-builtins}/extra-builtins.nix" {
    exec = exec';
  };

  flutter_overlay = _: pkgs: {
    flutter = pkgs.flutterPackages.dev;
  };

  pkgs = import sources.nixpkgs {
    overlays = [
      flutter_overlay
    ];
  };

  gitignoreSource =
    (import sources."gitignore.nix" { inherit (pkgs) lib; }).gitignoreSource;
  src = gitignoreSource ./..;

  lib = pkgs.lib;
  stdenv = pkgs.stdenv;

  # TODO: figure out how to use Nix mkOption correctly instead of doing this.
  target-android   = true;
  target-ios       = stdenv.isDarwin;
  target-web       = true;
  target-desktop   = true;

  flutterTools = { inherit (pkgs) flutter git; }
    // lib.optionalAttrs (target-android) { inherit (pkgs) android-studio; }
    // lib.optionalAttrs (target-ios)     { inherit (pkgs) cocoapods; }
    // lib.optionalAttrs (target-web)     { inherit (pkgs) google-chrome; }
    // lib.optionalAttrs (target-desktop && stdenv.isLinux) { inherit (pkgs) clang cmake ninja; }
    // lib.optionalAttrs (target-desktop && stdenv.isDarwin) { inherit (pkgs) cocoapods; }
    ;

  flutterConfig = "${pkgs.flutter}/bin/flutter config --android-sdk="
    + lib.optionalString (target-android)  " --android-studio-dir=${pkgs.android-studio.unwrapped} --enable-android"
    + lib.optionalString (!target-android) " --android-studio-dir= --no-enable-android"
    + lib.optionalString (target-ios)      " --enable-ios"
    + lib.optionalString (!target-ios)     " --no-enable-ios"
    + lib.optionalString (target-web)      " --enable-web"
    + lib.optionalString (!target-web)     " --no-enable-web"
    + lib.optionalString (target-desktop && stdenv.isLinux) " --enable-linux-desktop"
    + lib.optionalString (target-desktop && stdenv.isDarwin) " --enable-macos-desktop"
    + lib.optionalString (!target-desktop) " --no-enable-linux-desktop --no-enable-macos-desktop"
    ;

in rec
{
  inherit pkgs src;

  # Minimum tools required to build Note Maps.
  buildTools = { inherit (pkgs) go stdenv; } // flutterTools;

  # Additional tools required to build Note Maps in a more controlled
  # environment.
  ciTools = buildTools // {
    inherit (pkgs) coreutils findutils moreutils;
    inherit (pkgs) git gnugrep gnused;
  };

  # Additional tools useful for code work and repository maintenance.
  devTools = buildTools // {
    inherit (pkgs) niv;
  };

  buildInputs = builtins.attrValues ciTools;
  shellInputs = builtins.attrValues devTools;
  shellHook = ''
    export FLUTTER_SDK_ROOT=${pkgs.flutter.unwrapped}
    echo "Configuring Flutter..."
    ${flutterConfig}
    echo "Accepting Android licenses..."
    yes | ${pkgs.flutter}/bin/flutter doctor --android-licenses
  '';
}
