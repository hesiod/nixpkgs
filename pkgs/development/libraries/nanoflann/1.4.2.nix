{ callPackage, ... } @ args:

callPackage ./generic-cmake.nix ({
  version = "1.4.2";
  hash = "sha256-znIX1S0mfOqLYPIcyVziUM1asBjENPEAdafLud1CfFI=";
} // args)
