# Sioyek with Qt HiDPI scaling forced on.
#
# Replaces scripts/.local/bin/sioyek from the Arch setup. That script could not
# survive the move: it ended in `exec /usr/bin/sioyek`, and renaming the target
# to plain `sioyek` would have made the wrapper call itself, since the wrapper
# *is* sioyek on PATH. A build-time wrapper has no such ambiguity.
#
# Why it is needed: conf.d/xwayland.lua sets force_zero_scaling = true, so
# XWayland clients render at native pixel density instead of being upscaled as
# bitmaps (sharp text). Each toolkit then has to scale its own UI, which for Qt
# means these two variables — without them Sioyek's interface comes out tiny on
# the 2560x1600 panel at scale 1.25.
{
  symlinkJoin,
  sioyek,
  makeWrapper,
}:
symlinkJoin {
  name = "sioyek-hidpi";
  paths = [ sioyek ];
  nativeBuildInputs = [ makeWrapper ];

  postBuild = ''
    wrapProgram $out/bin/sioyek \
      --set QT_AUTO_SCREEN_SCALE_FACTOR 1 \
      --set QT_ENABLE_HIGHDPI_SCALING 1
  '';

  meta.mainProgram = "sioyek";
}
