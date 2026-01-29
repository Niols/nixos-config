{
  lib,
  stdenv,
  fetchurl,
}:

## NOTE: The synthesizer also exists in SFZ, which should give better sound
## quality. However, until we figure out a way to use those seamlessly in
## Ardour, we will rely on the SF2 variant instead.

stdenv.mkDerivation rec {
  pname = "soundfont-salamander-grand-piano";
  version = "V3+20200602";

  src = fetchurl {
    url = "https://freepats.zenvoid.org/Piano/SalamanderGrandPiano/SalamanderGrandPiano-SF2-${version}.tar.xz";
    sha256 = "sha256-Fe2wYde6YNWDMvctuo+M5AmIBIzHA/k15jIPN9ZQ4hM=";
  };

  installPhase = ''
    install -Dm644 SalamanderGrandPiano-*.sf2 $out/share/sounds/sf2/SalamanderGrandPiano.sf2
  '';

  meta = with lib; {
    description = "Acoustic grand piano soundfont";
    homepage = "https://freepats.zenvoid.org/Piano/acoustic-grand-piano.html";
    license = licenses.cc-by-30;
    platforms = platforms.all;
    maintainers = [ ];
  };
}
