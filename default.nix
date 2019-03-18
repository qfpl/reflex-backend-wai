{ reflex-platform ? import ./nix/reflex-platform.nix
, compiler   ? "ghc"
} :
let

  pkgs = reflex-platform.nixpkgs.pkgs;

  sources = {
    reflex-basic-host = import ./nix/reflex-basic-host.nix;
  };

  haskellPackages = reflex-platform.ghc.override {
    overrides = self: super: {
      reflex-basic-host = self.callPackage sources.reflex-basic-host {};
    };
  };

  drv = haskellPackages.callPackage ./reflex-backend-wai.nix { };
in
  drv
