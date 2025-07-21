# shell.nix
let
  pkgs = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/tarball/25.05";
    sha256 = "sha256:1915r28xc4znrh2vf4rrjnxldw2imysz819gzhk9qlrkqanmfsxd";
  }) { config.allowUnfree = true; };
in

pkgs.mkShell {
  buildInputs = [ 
    pkgs.foundry 
    pkgs.act
    pkgs.lcov
    pkgs.python3
    pkgs.poetry
  ];
}

