{ callPackage }:

{
  testImportedCMakePackage = callPackage ./test-imported-cmake-package.nix { };
}
