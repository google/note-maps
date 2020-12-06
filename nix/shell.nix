# Example shell.nix. Copy this to the parent directory to use nix-shell to load
# a consistent development environment for this project.

{ project ? import ./nix { }
}:
project.pkgs.mkShell {
  buildInputs = builtins.attrValues project.devTools;
}
