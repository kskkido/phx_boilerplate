{
  description = "A very basic flake";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils }:
  flake-utils.lib.eachDefaultSystem(system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      pnpm = pkgs.nodejs_22.pkgs.pnpm.override {
        version = "10.13.1";
        hash = "sha256-D57UjYCJlq4AeDX7XEZBz5owDe8u3cnpV9m75HaMXyg=";
      };
    in
    {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          beam.packages.erlang_26.elixir_1_18
          nodejs_22
          pnpm
        ];
      };
    }
  );
}

