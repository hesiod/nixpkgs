{ lib
, fetchFromGitHub
, stdenv
, mono
, openal
, SDL2
, noto-fonts-cjk-sans
#, noto-fonts-cjk-serif
, libusb1

, buildDotnetModule
, dotnetCorePackages
}:

#, makeWrapper, patchelf, stdenv, SDL, libglvnd, libogg, libvorbis, curl, openal }:
let
  runtimeIdentifier = dotnetCorePackages.systemToDotnetRid stdenv.targetPlatform.system;
in
#stdenv.mkDerivation rec {
buildDotnetModule rec {
  pname = "openbve";
  version = "1.8.4.4";

  src = fetchFromGitHub {
    owner = "leezer3";
    repo = "OpenBVE";
    rev = version;
    hash = "sha256-VEZkUSWZDyPk43c8Ox7isRnRRW31fELanDUBHjWQE8k=";
  };

  nugetDeps = ./deps.nix;

  projectFile = "OpenBVE.sln";
  projectFile0 = [
    "OpenBVE.sln"
    "source/OpenBVE/OpenBve.csproj"
    "source/AssimpParser/AssimpParser.csproj"
"source/CarXMLConvertor/CarXMLConvertor.csproj"
"source/DevTools/LBAHeader/LBAHeader.csproj"
"source/InputDevicePlugins/DefaultDisplayPlugin/DefaultDisplayPlugin.csproj"
"source/InputDevicePlugins/DenshaDeGoInput/DenshaDeGoInput.csproj"
"source/InputDevicePlugins/SanYingInput/SanYingInput.csproj"
"source/LibRender2/LibRender2.csproj"
"source/ObjectBender/ObjectBender.csproj"
"source/ObjectViewer/ObjectViewer.csproj"
"source/OpenBVE/OpenBve.csproj"
"source/OpenBveApi/OpenBveApi.csproj"
"source/Plugins/Formats.DirectX/Formats.DirectX.csproj"
"source/Plugins/Formats.Msts/Formats.Msts.csproj"
"source/Plugins/Object.Animated/Object.Animated.csproj"
"source/Plugins/Object.CsvB3d/Object.CsvB3d.csproj"
"source/Plugins/Object.DirectX/Object.DirectX.csproj"
"source/Plugins/Object.LokSim/Object.LokSim.csproj"
"source/Plugins/Object.Msts/Object.Msts.csproj"
"source/Plugins/Object.Wavefront/Object.Wavefront.csproj"
"source/Plugins/OpenBveAts/OpenBveAts.csproj"
"source/Plugins/Route.CsvRw/Route.CsvRw.csproj"
"source/Plugins/Route.Mechanik/Route.Mechanik.csproj"
"source/Plugins/Sound.Flac/Sound.Flac.csproj"
"source/Plugins/Sound.MP3/Sound.MP3.csproj"
"source/Plugins/Sound.RiffWave/Sound.RiffWave.csproj"
"source/Plugins/Sound.Vorbis/Sound.Vorbis.csproj"
"source/Plugins/Texture.Ace/Texture.Ace.csproj"
"source/Plugins/Texture.BmpGifJpegPngTiff/Texture.BmpGifJpegPngTiff.csproj"
"source/Plugins/Texture.Dds/Texture.Dds.csproj"
"source/Plugins/Texture.Tga/Texture.Tga.csproj"
"source/Plugins/Train.OpenBve/Train.OpenBve.csproj"
"source/Plugins/Win32PluginProxy/Win32PluginProxy.csproj"
"source/RouteManager2/RouteManager2.csproj"
"source/RouteViewer/RouteViewer.csproj"
"source/SoundManager/SoundManager.csproj"
"source/TrainEditor/TrainEditor.csproj"
"source/TrainEditor2/TrainEditor2.csproj"
"source/TrainManager/TrainManager.csproj"
  ];

  #projectFile = "source/OpenBVE/OpenBve.csproj";
  #dotnetFlags = [ "-p:Runtimeidentifier=${runtimeIdentifier}" ];



  # nativeBuildInputs = [ mono  ];
  #dotnet-sdk = dotnetCorePackages.sdk_7_0;
  #dotnet-runtime = dotnetCorePackages.runtime_7_0;

  buildInputs = [
    #mono
    noto-fonts-cjk-sans
    #openal
    #SDL2
    #libusb1
  ];

  meta = {
    description = "Crossplatform openarena client";
    homepage = "http://openarena.ws/";
    maintainers = with lib.maintainers; [ tmarkus ];
    #platforms = lib.platforms.unix;
    platforms = [ "x86_64-linux" ];
    license = lib.licenses.publicDomain;
  };
}
