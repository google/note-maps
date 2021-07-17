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

{
  description = "Note Maps";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        namePrefix = "notemaps";

        pkgs = import nixpkgs { inherit system;
          config = { allowUnfree = true; };
          overlays = [
            (self: super: {
              dart = import ./third_party/nixpkgs/dart {
                inherit (super) stdenv fetchurl unzip;
              };
              fastlane = import ./third_party/nixpkgs/fastlane {
                inherit (super) stdenv bundlerEnv ruby bundlerUpdateScript makeWrapper;
              };
            })
            (self: super: {
              flutterPackages =
                self.recurseIntoAttrs (import ./third_party/nixpkgs/flutter {
                  dart = super.dart;
                  #inherit (super) callPackage;
                });
            })
            (self: super: { flutter = super.flutterPackages.dev; })
          ];
        };

        localPackages = import ./packages.nix { inherit pkgs; };

        packages = {
          "${namePrefix}-web" = localPackages.app.web;
          "${namePrefix}-apk" = localPackages.app.apk;
        };

        devShell = pkgs.mkShell {
          inherit (localPackages) shellHook;
          nativeBuildInputs = localPackages.shellInputs;
        };

      in {
        inherit packages devShell;
        defaultPackage = self.packages.${system}."${namePrefix}-web";
      });
}

