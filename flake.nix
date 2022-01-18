# Copyright 2020-2022 Google LLC
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
    naersk = {
      url = "github:nix-community/naersk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, gomod2nix, naersk, rust-overlay }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        namePrefix = "notemaps";
        version = "0.2.0";
        pkgs = import nixpkgs {
          inherit system;
          config = {
            android_sdk.accept_license = true;
            allowUnfreePredicate = pkg:
              builtins.elem (nixpkgs.lib.getName pkg)
              [ "android-studio-stable" ];
          };
          overlays = [
            gomod2nix.overlay
            rust-overlay.overlay
            (self: super: {
              fastlane = import ./third_party/nixpkgs/fastlane {
                inherit (super)
                  stdenv bundlerEnv ruby bundlerUpdateScript makeWrapper;
              };
            })
          ];
        };
      in with pkgs;
      let
        goPackages = import ./go.nix { inherit pkgs; };
        mkRustPackages = (rustExtensions:
          let
            rust = pkgs.rust-bin.nightly.latest.default.override {
              extensions = [ "cargo" "rust-src" "rust-std" "rustc" ]
                ++ rustExtensions;
            };
            naersk-lib = naersk.lib."${system}".override {
              cargo = rust;
              rustc = rust;
            };
          in {
            note-maps-rust = naersk-lib.buildPackage {
              pname = "note-maps-rust";
              inherit version;
              src = self;
              nativeBuildInputs = with pkgs; [
                clang
                clangStdenv # for flutter to build linux desktop apps
                pkg-config
                rust
              ];
              copyLibs = true;
            };
          });
      in {
        packages = { "${namePrefix}" = goPackages."${namePrefix}"; };
        devShell = pkgs.mkShell {
          inputsFrom = with pkgs;
            [ go gomod2nix ] ++ builtins.attrValues goPackages
            ++ builtins.attrValues (mkRustPackages [
              "clippy-preview"
              "llvm-tools-preview"
              "rust-analyzer-preview"
              #"rust-docs" # not available in all platforms
              #"rustc-docs" # not available in all platforms
              "rustfmt-preview"
            ]);
          depsBuildBuild = with pkgs; [ cargo-edit cargo-tarpaulin ];
        };
        defaultPackage = self.packages.${system}."${namePrefix}";
      });
}
