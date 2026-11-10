## myi3lock: i3lock-fancy's look, in one executable. See `myi3lock.c`.
{
  stdenv,
  pkg-config,
  cairo,
  pango,
  libx11,
  i3lock-color,
  i3lock-fancy,
}:

stdenv.mkDerivation {
  pname = "myi3lock";
  version = "0";

  src = ./myi3lock.c;
  dontUnpack = true;

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    cairo
    pango
    libx11
  ];

  buildPhase = ''
    runHook preBuild
    $CC -O2 -Wall -Wextra -o myi3lock $src \
      -DI3LOCK_COLOR='"${i3lock-color}/bin/i3lock-color"' \
      -DLOCK_ICON='"${i3lock-fancy.src}/icons/lock.png"' \
      -DLOCK_ICON_DARK='"${i3lock-fancy.src}/icons/lockdark.png"' \
      $(pkg-config --cflags --libs cairo cairo-xlib pangocairo x11) -lm
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 myi3lock $out/bin/myi3lock
    runHook postInstall
  '';
}
