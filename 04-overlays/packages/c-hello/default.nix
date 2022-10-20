{ stdenv, lib, mySource, autoreconfHook, ... }:  # Build depend

stdenv.mkDerivation rec {
  inherit (mySource) pname version src;
  nativeBuildInputs = [ autoreconfHook ];
  passthru = { runnable = true; };
}
