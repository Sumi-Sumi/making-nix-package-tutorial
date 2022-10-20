{
  description = "Making package with flake but not using flake-utils";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixos-22.05";

  outputs = { self, nixpkgs }:
    let

      # to work with older version of flakes
      lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";

      # Generate a user-friendly version number.
      version = builtins.substring 0 8 lastModifiedDate;

      # System types to support.
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ../sample-overlays. }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });

    in
    {
      packages = forAllSystems (system: 
        let
          pkgs = nixpkgsFor.${system};
        in
        with pkgs; rec {
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
        }
      );
    };
}
