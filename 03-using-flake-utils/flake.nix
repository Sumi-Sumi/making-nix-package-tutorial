{
  description = "Making package with flake and flake-utils";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixos-22.05";
  # Using flake-utils
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
  let
    # to work with older version of flakes
    lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";

    # Generate a user-friendly version number.
    version = builtins.substring 0 8 lastModifiedDate;
  in
    # flake-utils.lib.eachDefaultSystem (system:
    flake-utils.lib.eachSystem ["x86_64-linux" "aarch64-linux"] (system:
      let pkgs = nixpkgs.legacyPackages.${system}; in
        with pkgs; {
          packages = flake-utils.lib.flattenTree rec{
            c-hello = stdenv.mkDerivation {
              name = "c-hello-${version}";
              src = ../sample-overlays/packages/c-hello;
              nativeBuildInputs = [ autoreconfHook ];
            };
            go-hello = buildGoModule {
              pname = "go-hello";
              inherit version;
              src = ../sample-overlays/packages/go-hello;
              vendorSha256 = "sha256-pQpattmS9VmO3ZIQUFn66az8GSmB4IvYhTTCFn6SUmo=";
            };
            default = c-hello;
          };
          apps = rec {
            c-hello = flake-utils.lib.mkApp { drv = packages.c-hello; };
            go-hello = flake-utils.lib.mkApp { drv = packages.go-hello; };
            default = c-hello;
          };
        }
  );
}
