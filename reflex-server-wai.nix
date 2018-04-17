{ mkDerivation, base, bytestring, containers, http-types, mtl
, reflex, reflex-basic-host, stdenv, stm, wai, warp
}:
mkDerivation {
  pname = "reflex-server-wai";
  version = "0.1.0.0";
  src = ./.;
  isLibrary = true;
  isExecutable = true;
  libraryHaskellDepends = [ base containers mtl reflex stm wai ];
  executableHaskellDepends = [
    base bytestring http-types reflex reflex-basic-host stm wai warp
  ];
  license = stdenv.lib.licenses.bsd3;
}
