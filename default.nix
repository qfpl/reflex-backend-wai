{ reflex-platform ? import ./reflex-platform.nix
, compiler   ? "ghc"
} :
let

  pkgs = reflex-platform.nixpkgs.pkgs;

  sources = {
    reflex-basic-host = import ./reflex-basic-host.nix;
  };

  haskellPackages = reflex-platform.ghc.override {
    overrides = self: super: {
      reflex-basic-host = self.callPackage sources.reflex-basic-host {};
      ghc = super.ghc // { withPackages = super.ghc.withHoogle; };
      ghcWithPackages = self.ghc.withPackages;
    };
  };

  drv = haskellPackages.callPackage ./reflex-server-wai.nix { };
in
  drv
