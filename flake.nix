{
  description = "A basic flake with a shell";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.systems.url = "github:nix-systems/default";
  inputs.flake-utils = {
    url = "github:numtide/flake-utils";
    inputs.systems.follows = "systems";
  };

  outputs =
    { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        elixir_1_18_0 = pkgs.beam.packages.erlang_26.elixir_1_17.override
          rec {
            version = "1.18.0";
            sha256 = "sha256-fT3J8h2uuJ+dSR58kwlUkN023yFlmTwq2/O12KbjJc4=";
          };
        pnpm_10_13_1 = pkgs.nodejs_22.pkgs.pnpm.override
          rec {
            version = "10.13.1";
            hash = "sha256-D57UjYCJlq4AeDX7XEZBz5owDe8u3cnpV9m75HaMXyg=";
          };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            elixir_1_18_0
            nodejs_22
            pnpm_10_13_1
          ];
        };
      }
    );
}

