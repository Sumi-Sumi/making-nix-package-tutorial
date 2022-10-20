{ stdenv, lib, mySource, ... }:

stdenv.mkDerivation rec {
  inherit (mySource) pname version src;
  passthru = { runnable = true; };
}
