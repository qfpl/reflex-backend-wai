{ mkDerivation, base, bytestring, http-types, mtl, reflex
, reflex-basic-host, stdenv, stm, wai, warp
}:
mkDerivation {
  pname = "reflex-server-wai";
  version = "0.1.0.0";
  src = ./.;
  libraryHaskellDepends = [
    base bytestring http-types mtl reflex reflex-basic-host stm wai
    warp
  ];
  license = stdenv.lib.licenses.bsd3;
}
