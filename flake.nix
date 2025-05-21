# /qompassai/gnupg/flake.nix
# ------------------------------
# Copyright (C) 2025 Qompass AI, All rights reserved

{
  description = "Qompass AI GnuPG/OpenPGP Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    packages.x86_64-linux.gnupg = nixpkgs.legacyPackages.x86_64-linux.gnupg;
    packages.x86_64-linux.default = self.packages.x86_64-linux.gnupg;
  };
}
