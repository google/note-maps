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

  third_party_overlays = [
    (self: super: {
      dart = self.callPackage ../third_party/nixpkgs/dart {
        inherit (super) stdenv fetchurl unzip;
      };
    })
    (self: super: {
      flutterPackages =
        self.recurseIntoAttrs (self.callPackage ../third_party/nixpkgs/flutter {
          dart = super.dart;
          inherit (super) callPackage;
        });
    })
  ];

  flutter_overlay = _: pkgs: {
    flutter = pkgs.flutterPackages.dev;
  };

  pkgs = import sources.nixpkgs {
    overlays = third_party_overlays ++ [
      flutter_overlay
    ];
  };

  gitignoreSource =
    (import sources.gitignore { inherit (pkgs) lib; }).gitignoreSource;
  src = gitignoreSource ./..;

  lib = pkgs.lib;
  stdenv = pkgs.stdenv;

  # TODO: figure out how to use Nix mkOption correctly instead of doing this.
  install-flutter  = true;
  target-android   = stdenv.isLinux;
  target-ios       = stdenv.isDarwin;
  target-web       = true;
  target-desktop   = true;

  # TODO: make Nix support installing Flutter on OSX.
  # TODO: make Nix support installing Chrome on OSX.
  flutterTools = lib.optionalAttrs (install-flutter) { inherit (pkgs) flutter; }
    #// lib.optionalAttrs (target-android) { inherit (pkgs) android-studio; }
    // lib.optionalAttrs (target-ios)     { inherit (pkgs) cocoapods; }
    // lib.optionalAttrs (target-desktop && stdenv.isLinux)  { inherit (pkgs) clang cmake ninja; }
    // lib.optionalAttrs (stdenv.isDarwin) { inherit (pkgs) xcodebuild; }
    // lib.optionalAttrs (target-desktop && stdenv.isDarwin) { inherit (pkgs) cocoapods; }
    ;

  # TODO: make Nix support installing Flutter on OSX.
  flutter = ""
    + lib.optionalString (install-flutter)  "${pkgs.flutter}/bin/flutter"
    + lib.optionalString (!install-flutter) "flutter"
    ;

  flutterConfig = "${flutter} config --android-sdk="
    + lib.optionalString (target-android)  " --enable-android" # --android-studio-dir=${pkgs.android-studio.unwrapped}"
    + lib.optionalString (!target-android) " --no-enable-android" # --android-studio-dir="
    + lib.optionalString (target-ios)      " --enable-ios"
    + lib.optionalString (!target-ios)     " --no-enable-ios"
    + lib.optionalString (target-web)      " --enable-web"
    + lib.optionalString (!target-web)     " --no-enable-web"
    + lib.optionalString (target-desktop && stdenv.isLinux) " --enable-linux-desktop"
    + lib.optionalString (target-desktop && stdenv.isDarwin) " --enable-macos-desktop"
    + lib.optionalString (!target-desktop) " --no-enable-linux-desktop --no-enable-macos-desktop"
    ;

  fdroid = pkgs.writeShellScriptBin "fdroid" ''
    docker run --rm \
      -u $(id -u):$(id -g) \
      -v $(pwd):/repo \
      registry.gitlab.com/fdroid/docker-executable-fdroidserver:master \
      "$@"
  '';

  sw_vers = pkgs.writeShellScriptBin "sw_vers" ''
    echo "ProductName:	macOS"
    echo "ProductVersion:	11.1"
    echo "BuildVersion:	20C69"
  '';

  dart2nix = pkgs.runCommandLocal "dart2nix" {
    script = ./dart2nix.sh;
    nativeBuildInputs = [ pkgs.makeWrapper ];
  } ''
    makeWrapper $script $out/bin/dart2nix.sh \
      --prefix PATH : ${lib.makeBinPath (with pkgs; [ jq yq mustache-go ])}
  '';

  pubCache = pkgs.flutter.mkPubCache { dartPackages = import ../flutter/nm_app/deps.nix; };

  env = lib.optionalAttrs (install-flutter) {
    FLUTTER_SDK_ROOT = "${pkgs.flutter.unwrapped}";
    PUB_CACHE = "${pubCache}/libexec/pubcache";
  };

  # Minimum tools required to build Note Maps.
  buildTools = { inherit (pkgs) git go stdenv; inherit fdroid; } // flutterTools;

  # Build a Flutter app! It's not a pure deriviation though: it requires the
  # following commands (or something similar) to be run in the root of this
  # repo:
  #   ( XDG_CONFIG_HOME=$pwd/.config \
  #     XDG_CACHE_HOME=$pwd/.cache \
  #     nix-shell --run 'flutter precache' )
  # This is wrapped up in ./nix.mk.
  mkFlutterApp =
  { build # 'appbundle', 'ios', 'web', etc.
  , name ? "note-maps-${build}"
  }: stdenv.mkDerivation ({
    inherit name src;
    buildInputs = builtins.attrValues (buildTools // {
      inherit (pkgs) coreutils findutils moreutils;
      inherit (pkgs) stdenvNoCC;
      inherit (pkgs) which unzip;
      inherit sw_vers;
    });
    PUB_CACHE = "${pubCache}/libexec/pubcache";
    buildPhase = ''
      export src2=$TMP/mutable-src
      cp --recursive $src $src2
      chmod -R u+wX $src2
      export HOME=$src2/.config
      export XDG_CONFIG_HOME=$src2/.config
      export XDG_CACHE_HOME=$src2/.cache
      make -e OUTDIR=$out DEBUG= build
    '';
    installPhase = ''
      cd $out
      ${pkgs.tree}/bin/tree
    '';
  } // env);

in with builtins ; rec
{
  inherit pkgs src buildTools;

  # So that it can be built and cached on its own with
  # `nix-build ./nix -A pubCache | cachix push ...`
  inherit pubCache;

  # Additional tools required to build Note Maps in a more controlled
  # environment.
  ciTools = buildTools // {
    inherit (pkgs) coreutils findutils moreutils;
    inherit (pkgs) gnugrep gnused;
  };

  # Additional tools useful for code work and repository maintenance.
  devTools = buildTools // {
    inherit (pkgs) bash niv;
    inherit dart2nix;
  };

  buildInputs = builtins.attrValues ciTools;
  shellInputs = builtins.attrValues devTools;

  # Convert env to an 'export KEY=VALUE ...' string:
  shellHook = "export " + (
    builtins.concatStringsSep " " (
      attrValues ( mapAttrs (name: value: name+"="+value) env )
    )
  );

  app = {
  } // lib.optionalAttrs (target-android) {
    appbundle = mkFlutterApp { build = "appbundle"; };
  } // lib.optionalAttrs (target-ios) {
    ios = mkFlutterApp { build = "ios"; };
  } // lib.optionalAttrs (target-web) {
    web = mkFlutterApp { build = "web"; };
  } // lib.optionalAttrs (target-desktop && stdenv.isDarwin) {
    macos = mkFlutterApp { build = "macos"; };
  } // lib.optionalAttrs (target-desktop && stdenv.isLinux) {
    linux = mkFlutterApp { build = "linux"; };
  };
}
