{ callPackage, ... } @ args:

callPackage ./generic-cmake.nix ({
  version = "1.5.0";
  hash = "sha256-vPLL6l4sFRi7nvIfdMbBn/gvQ1+1lQHlZbR/2ok0Iw8=";
} // args)
