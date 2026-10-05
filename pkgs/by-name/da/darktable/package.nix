{
  lib,
  stdenv,
  fetchurl,
  versionCheckHook,
  gitUpdater,

  # minimal build without any optional dependencies
  minimal ? false,

  # nativeBuildInputs
  cmake,
  desktop-file-utils,
  intltool,
  llvmPackages,
  ninja,
  perl,
  pkg-config,
  wrapGAppsHook3,
  saxon,
  perl5Packages,

  # buildInputs
  SDL2,
  adwaita-icon-theme,
  cairo,
  cups,
  curl,
  exiv2,
  glib,
  gmic,
  graphicsmagick,
  gtk3,
  icu,
  isocodes,
  json-glib,
  lcms2,
  lensfun,
  libavif,
  libexif,
  libgphoto2,
  libheif,
  libjpeg,
  libjxl,
  libpng,
  libraw,
  librsvg,
  libsecret,
  libtiff,
  libwebp,
  libxml2,
  libxslt,
  lua5_4,
  openexr,
  openjpeg,
  osm-gps-map,
  portmidi,
  potrace,
  pugixml,
  sqlite,
  zlib,

  withColord ? lib.meta.availableOn stdenv.hostPlatform colord && !minimal,
  colord,
  colord-gtk,

  withOpenCl ? stdenv.hostPlatform.isLinux && !minimal,
  ocl-icd,
  opencl-headers,

  # enable AI tools
  withAi ? false,
  libarchive,
  onnxruntime,

  # optional lint step
  withXmllint ? !minimal,

  # Darwin only
  gtk-mac-integration,
}:

let
  pugixml-shared = pugixml.override { shared = true; };
in
stdenv.mkDerivation (finalAttrs: {
  version = "5.6.2";
  pname = "darktable";

  src = fetchurl {
    url = "https://github.com/darktable-org/darktable/releases/download/release-${finalAttrs.version}/darktable-${finalAttrs.version}.tar.xz";
    hash = "sha256-0tqSxnBAHTULV2Qx8h5YvuQDSOH1B4IBqKG4wnBYWDQ=";
  };

  __structuredAttrs = true;
  strictDeps = true;

  nativeBuildInputs = [
    cmake
    desktop-file-utils
    intltool
    libxslt # xsltproc, used by tools/generate_styles_string.sh
    ninja
    perl
    pkg-config
    wrapGAppsHook3
    saxon # Use Saxon instead of libxslt to fix XSLT generate-id() consistency issues
    perl5Packages.Po4a
  ]
  ++ lib.optionals withXmllint [
    (lib.getBin libxml2)
  ];

  buildInputs = [
    adwaita-icon-theme
    cairo
    curl
    exiv2
    glib
    gtk3
    json-glib
    lcms2
    lensfun
    libexif
    libjpeg
    libpng
    libraw
    librsvg
    libtiff
    libxml2
    potrace
    pugixml-shared
    sqlite
    zlib
  ]
  ++ lib.optionals (!minimal) [
    SDL2
    cups
    gmic
    graphicsmagick
    icu
    isocodes
    libavif
    libgphoto2
    libheif
    libjxl
    libsecret
    libwebp
    lua5_4
    openexr
    openjpeg
    osm-gps-map
    portmidi
  ]
  ++ lib.optionals withAi [
    libarchive
    onnxruntime
  ]
  ++ lib.optionals withColord [
    colord
    colord-gtk
  ]
  ++ lib.optionals withOpenCl [
    opencl-headers
    ocl-icd
  ]
  ++ lib.optional stdenv.hostPlatform.isDarwin gtk-mac-integration
  ++ lib.optional stdenv.cc.isClang llvmPackages.openmp;

<<<<<<< HEAD
  cmakeFlags = [
    # Prevents -march=native.
    "-DBINARY_PACKAGE_BUILD=1"
    "-DBUILD_USERMANUAL=False"
    "-DRAWSPEED_MARCH=-mtune=generic"
  ]
  ++ lib.optionals withAi [
    (lib.cmakeBool "USE_AI" true)
    (lib.cmakeBool "ONNXRUNTIME_OFFLINE" true)
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    "-DUSE_COLORD=OFF"
    "-DUSE_KWALLET=OFF"
  ];
||||||| parent of a00dc414327d (darktable: unvendor and clean up dependencies)
  cmakeFlags = [
    "-DBUILD_USERMANUAL=False"
  ]
  ++ lib.optionals withAi [
    (lib.cmakeBool "USE_AI" true)
    (lib.cmakeBool "ONNXRUNTIME_OFFLINE" true)
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    "-DUSE_COLORD=OFF"
    "-DUSE_KWALLET=OFF"
  ];
=======
  cmakeFlags = lib.mapAttrsToList lib.cmakeBool {
    # note: options are documented in DefineOptions.cmake

    # Bit of a misnomer, makes Darktable not try to use -march=native
    # (the cc wrappers override -march=native anyways, but let's specify it here for clarity)
    CUSTOM_CFLAGS = true;
    BINARY_PACKAGE_BUILD = true;

    DONT_USE_INTERNAL_LUA = true;
    DONT_USE_INTERNAL_LIBRAW = true;

    USE_XMLLINT = withXmllint;

    USE_AI = withAi;
    ONNXRUNTIME_OFFLINE = withAi;

    USE_COLORD = withColord;
    USE_KWALLET = !stdenv.hostPlatform.isDarwin;

    USE_OPENCL = withOpenCl;
    TESTBUILD_OPENCL_PROGRAMS = false;

    USE_OPENMP = true;

    USE_CAMERA_SUPPORT = true;
    USE_LIBRAW = true;

    USE_LUA = !minimal;
    USE_MAP = !minimal;
    USE_LIBSECRET = !minimal;
    USE_GMIC = !minimal;
    USE_GRAPHICSMAGICK = !minimal;
    USE_PORTMIDI = !minimal;
    USE_OPENJPEG = !minimal;
    USE_JXL = !minimal;
    USE_WEBP = !minimal;
    USE_AVIF = !minimal;
    USE_HEIF = !minimal;
    USE_OPENEXR = !minimal;
    USE_ICU = !minimal;
    USE_SDL2 = !minimal;

    BUILD_PRINT = !minimal;

    BUILD_NOISE_TOOLS = !minimal;
    BUILD_CURVE_TOOLS = !minimal;

    BUILD_CMSTEST = true;

    # built darktable-rs-identify does not work without further patching
    BUILD_TOOLS = false;
  };
>>>>>>> a00dc414327d (darktable: unvendor and clean up dependencies)

  # darktable changed its rpath handling in commit
  # 83c70b876af6484506901e6b381304ae0d073d3c and as a result the
  # binaries can't find libdarktable.so, so change LD_LIBRARY_PATH in
  # the wrappers:
  preFixup =
    let
      libPathEnvVar = if stdenv.hostPlatform.isDarwin then "DYLD_LIBRARY_PATH" else "LD_LIBRARY_PATH";
      libPathPrefix =
        "$out/lib/darktable"
        + lib.optionalString (withAi && stdenv.hostPlatform.isLinux) ":${lib.getLib onnxruntime}/lib"
        + lib.optionalString stdenv.hostPlatform.isLinux ":${ocl-icd}/lib";
    in
    ''
      gappsWrapperArgs+=(
        --prefix ${libPathEnvVar} ":" "${libPathPrefix}"
      )
    '';

  postPatch = ''
    # remove unused vendored libraries to ensure they won't get accidentally picked up
    rm -r src/external/{LibRaw,LibRaw-cmake,lua}

    patchShebangs ./tools/generate_styles_string.sh

    rm -r src/external/OpenCL
    # note: will work without this due to cc wrapper include path handling,
    # but patch the directory anyways in order to prevent possible issues in the future
    substituteInPlace src/CMakeLists.txt \
      --replace-fail 'include_directories(SYSTEM ''${CMAKE_CURRENT_SOURCE_DIR}/external/OpenCL)' 'include_directories(SYSTEM ${opencl-headers}/include/OpenCL)'
  '';

  # darktable hangs in versionCheckHook on darwin for an unknown reason, use darktable-cli instead
  # (possibly related to accessing /var/empty/.config/darktable, but writableTmpDirAsHomeHook did not help as of v5.6.2
  doInstallCheck = !stdenv.hostPlatform.isDarwin;
  nativeInstallCheckInputs = [
    versionCheckHook
  ];

  passthru.updateScript = gitUpdater {
    rev-prefix = "release-";
    odd-unstable = true;
    url = "https://github.com/darktable-org/darktable.git";
  };

  meta = {
    description = "Virtual lighttable and darkroom for photographers";
    homepage = "https://www.darktable.org";
    changelog = "https://github.com/darktable-org/darktable/releases/tag/release-${finalAttrs.version}";
    mainProgram = "darktable";
    license = lib.licenses.gpl3Plus;
    platforms = with lib.platforms; linux ++ darwin;
    maintainers = with lib.maintainers; [
      flosse
      mrVanDalo
      freyacodes
    ];
  };
})
