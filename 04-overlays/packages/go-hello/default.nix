{ stdenv, lib, mySource, buildGoModule, ... }:

buildGoModule {
  inherit (mySource) pname version src vendorSha256;

  passthru = { runnable = true; };
}
