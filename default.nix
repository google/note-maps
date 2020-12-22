{ project ? import ./nix { }, pkgs ? project.pkgs }:
{
  hello = import ./hello.nix { inherit (pkgs) stdenv fetchurl perl; };
  helloworld = pkgs.writeShellScriptBin "hellome" "echo Hello $USER";
}
