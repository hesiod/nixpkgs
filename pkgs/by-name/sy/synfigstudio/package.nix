{
  lib,
  stdenv,
  fetchFromGitHub,
  pkg-config,
  wrapGAppsHook3,
  gitUpdater,
  cmake,
  intltool,

  cairo,
  ffmpeg,
  gettext,
  glibmm_2_4,
  libmng,
  gtk3,
  gtkmm3,
  libjack2,
  libsigcxx_2_0,
  libxmlxx,
  mlt,
  imagemagick,
  adwaita-icon-theme,
  harfbuzz,
  freetype,
  fontconfig,
  fribidi,
  openexr,
  fftw,
  libtool,
}:


stdenv.mkDerivation (finalAttrs: {
  pname = "synfigstudio";

  version = "1.5.5";
  src = fetchFromGitHub {
    owner = "synfig";
    repo = "synfig";
    rev = "v${finalAttrs.version}";
    hash = "sha256-5jVd+YqHVHKkePXBb3zjXEVlgdlU6Yb6LC4CurvsBtE=";
  };

  __structuredAttrs = true;
  strictDeps = true;

  nativeBuildInputs = [
    pkg-config
    gettext
    intltool
    wrapGAppsHook3
    cmake
  ];

  buildInputs = [
    libtool
    cairo
    glibmm_2_4
    gtk3
    gtkmm3
    imagemagick
    libjack2
    libsigcxx_2_0
    libxmlxx
    mlt
    fontconfig
    ffmpeg
    adwaita-icon-theme
    openexr
    fftw
    fribidi
    harfbuzz
    freetype
    libmng
  ];

  enableParallelBuilding = true;

  passthru = {
    updateScript = gitUpdater { rev-prefix = "v"; };
  };

  meta = {
    description = "2D animation program";
    homepage = "https://www.synfig.org";
    changelog = "https://github.com/synfig/synfig/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.gpl3Plus;
    mainProgram = "synfigstudio";
    maintainers = [ ];
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
})
