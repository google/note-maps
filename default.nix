{ project ? import ./nix { }, pkgs ? project.pkgs }:
{
  inherit pkgs;
  inherit (project) app;
}
