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
    gomod2nix.url = "github:tweag/gomod2nix";
  };

  outputs = { self, nixpkgs, flake-utils, gomod2nix }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        namePrefix = "notemaps";
        pkgs = import nixpkgs {
          inherit system;
          config = { allowUnfree = true; };
          overlays = [
            gomod2nix.overlay
            (self: super: {
              fastlane = import ./third_party/nixpkgs/fastlane {
                inherit (super) stdenv bundlerEnv ruby bundlerUpdateScript makeWrapper;
              };
            })
          ];
        };
        goPackages = import ./go.nix { inherit pkgs; };
      in
      {
        packages = { "${namePrefix}" = goPackages."${namePrefix}"; };
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            go
            pkgs.gomod2nix
          ];
        };
        defaultPackage = self.packages.${system}."${namePrefix}";
      });
}
