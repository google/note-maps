let
  pkgs = (import ./nix {}).pkgs;
  mkDerivation = pkgs.stdenv.mkDerivation;
in mkDerivation {
  name = "graphviz";
  src = ./graphviz-2.38.0.tar.gz;
}
