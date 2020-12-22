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
, includeFlutter ? false
, targetAndroid ? false
, targetIos ? false
, targetDesktop ? false
, targetWeb ? false
, fixAutoPatchelfHook ? false
}:
let
  config = { android_sdk.accept_license = true; };

  # Some packages from unstable need the fix in
  # https://github.com/NixOS/nixpkgs/pull/106830
  unstable_patched =
    import sources.unstable-fix-autopatchelfhook {
      inherit config;
    };
  unstable_patched_overlay = _: pkgs:
    pkgs.lib.optionalAttrs (fixAutoPatchelfHook) {
      inherit (unstable_patched) androidenv;
    };

  unstable = import sources.unstable {
    inherit config;
  };
  unstable_overlay = _: pkgs: { inherit (unstable) cocoapods jdk; };

  android_overlay = _: pkgs: pkgs.lib.optionalAttrs (targetAndroid) {
    androidsdk = (pkgs.androidenv.composeAndroidPackages {
      buildToolsVersions = [ "28.0.3" ];
      platformVersions = [ "29" ];
      platformToolsVersion = "29.0.6";
      includeNDK = true;
      ndkVersion = "21.0.6113669";
      abiVersions = [ "x86-64" ];
    }).androidsdk;
  };

  pkgs = import sources.nixpkgs {
    inherit config;
    overlays = [
      unstable_patched_overlay
      unstable_overlay
      android_overlay
    ];
  };

  gitignoreSource =
    (import sources."gitignore.nix" { inherit (pkgs) lib; }).gitignoreSource;
  src = gitignoreSource ./..;

  lib = pkgs.lib;
  stdenv = pkgs.stdenv;

  flutterTools =
    lib.optionalAttrs (includeFlutter) { inherit (pkgs) flutter-dev git; };

  flutterAndroidTools = { inherit (pkgs) androidsdk jdk; };

  flutterIosTools = { }
    lib.optionalAttrs(stdenv.isDarwin) { inherit (pkgs) cocoapods; };

  # Flutter only builds desktop apps for the host platform, so all tools
  # required specifically for this target are platform-specific.
  flutterDesktopTools = { }
    // lib.optionalAttrs(stdenv.isLinux) { inherit (pkgs) clang cmake ninja; }
    // lib.optionalAttrs(stdenv.isDarwin) { inherit (pkgs) cocoapods; };

in rec
{
  inherit pkgs src;

  # Minimum tools required to build Note Maps.
  buildTools = {
    inherit (pkgs) go gnumake;
  } // flutterTools
    // lib.optionalAttrs(targetAndroid) flutterAndroidTools
    // lib.optionalAttrs(targetIos) flutterIosTools
    // lib.optionalAttrs(targetDesktop) flutterDesktopTools;

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
  shellHook = lib.optionalString (targetAndroid) ''
    export ANDROID_HOME="${pkgs.androidsdk}/libexec/android-sdk"
    export JAVA_HOME="${pkgs.jdk}"
  '';
}
