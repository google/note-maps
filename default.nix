{ project ? import ./nix { }, pkgs ? project.pkgs }:
{
  inherit pkgs;
}
