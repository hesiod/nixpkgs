{ lib, stdenv, cmake, writeTextFile, breakpointHook }:

{ pkg
  # Name of the installed CMake package
, cmakePkgName ? pkg.pname

  # whether to specify a required version in the find_package call
  # (only works if the package installs a version file, either
  # <lowercasePackageName>-config-version.cmake
  # or <PackageName>ConfigVersion.cmake
  # See https://cmake.org/cmake/help/v3.26/command/find_package.html#version-selection
, checkVersion ? true
  # Whether to request an exact version match in the find_package call
, checkVersionExact ? checkVersion

, debug ? false
  # enable find_package debugging
, debugFindPkg ? debug
  # enable try_compile (include checking) debugging (requires CMake>=3.25)
, debugTryCompile ? debug

  # Libraries that should be available after find_package
, expectedLibraries ? [ ]

  # Libraries used for checking includes
, checkLibraries ? [ ]
  # Include files to check
, checkIncludes ? [ ]
}:

let
  # NOTE: These definitions are not perfect and might let some incorrect names through.
  isValidVariableReference = s: builtins.match "[a-zA-Z0-9/_.+-]+" s != null;
  isValidListItem = s: builtins.match "[^;]+" s != null;
  assertValidListItem = s: lib.throwIfNot (isValidListItem s) "invalid list item \"${s}\"" s;
  assertValidVariableReference = s: lib.throwIfNot (isValidVariableReference s) "invalid variable reference \"${s}\"" s;
  toCMakeList = list: lib.concatMapStringsSep ";" assertValidListItem list;
in
(
  assert checkVersionExact -> checkVersion;
  assert checkIncludes != [ ] -> checkLibraries != [ ];

  stdenv.mkDerivation rec {
    pname = "test-imported-cmake-package-${pkg.pname}";
    version = pkg.version;

    nativeBuildInputs = [ cmake ];
    buildInputs = [
      # Will fall back to out or the default output if dev does not exist
      (lib.getOutput "dev" pkg)
    ];

    cmakeFlags =
      # useful for debugging if find_package fails
      lib.optionals debugFindPkg [ "--debug-find-pkg=${cmakePkgName}" ]
      # requires CMake>=3.25
      # since CMake<3.25 won't complain, we can always add it
      ++ lib.optionals debugTryCompile [ "--debug-trycompile" ];

    src = writeTextFile {
      name = "${pname}-src";

      text = ''
        cmake_minimum_required(VERSION 3.24)
        project(${pname} C CXX)

        find_package(${cmakePkgName}
          ${lib.optionalString checkVersion pkg.version}
          ${lib.optionalString checkVersionExact "EXACT"}
          REQUIRED)

        get_property(imported_targets DIRECTORY "''${CMAKE_CURRENT_SOURCE_DIR}" PROPERTY IMPORTED_TARGETS)

        message(STATUS "Available imported targets after find_package(${cmakePkgName}): \"''${imported_targets}\"")

        set(expected_libraries ${toCMakeList expectedLibraries})
        foreach(lib ''${expected_libraries})
          message(CHECK_START "Checking ''${lib}")
          if(lib IN_LIST imported_targets)
            message(CHECK_PASS "available as imported target")
          else()
            message(CHECK_FAIL "not available as imported target")
            message(SEND_ERROR "Expected to find imported library \"''${lib}\"")
          endif()
        endforeach()

        include(CheckIncludeFileCXX)

        set(CMAKE_REQUIRED_LIBRARIES ${toCMakeList checkLibraries})

        ${lib.concatMapStringsSep "\n" (include:
          let varname = "HAVE_${assertValidVariableReference include}";
          in
            ''
              check_include_file_cxx(${include} ${varname})
              if(NOT ${varname})
                message(SEND_ERROR "Failed include test for \"${include}\"")
              endif()
            '')
          checkIncludes}
      '';

      destination = "/CMakeLists.txt";
    };

    failureHook = ''
      local errorlog='CMakeFiles/CMakeError.log'

      echo -n "Checking for CMake error log \"$errorlog\"... "
      if [[ -f "$errorlog" ]]; then
        echo "exists!"
        echo
        echo "####################################"
        echo "###     Begin CMakeError.log     ###"
        echo "####################################"
        echo

        cat "$errorlog"

        echo "####################################"
        echo "###      End CMakeError.log      ###"
        echo "####################################"
        echo
      else
        echo "does not exist!"
      fi
    '';

    dontBuild = true;
    dontFixup = true;

    installPhase = "mkdir $out";

    meta.timeout = 60;
  }
)
