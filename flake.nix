{
  description = "Making package tutorial for nix";

  outputs = { self }: {
    templates = {
      without-flake = {
        path = ./01-without-flake;
        description = "Making package without flake";
      };
      using-flake-without-flake-utils = {
        path = ./02-using-flake-without-flake-utils;
        description = "Making package with flake but not using flake-utils";
      };
      using-flake-utils = {
        path = ./03-using-flake-utils;
        description = "Making package with flake and flake-utils";
      };
      overlays = {
        path = ./04-overlays;
        description = "Making overlays package";
      };
      nvfetcher = {
        path = ./05-nvfetcher;
        description = "Making package using nvfetcher";
      };
    };
    templates.default = self.templates.nvfetcher;
  };
}
