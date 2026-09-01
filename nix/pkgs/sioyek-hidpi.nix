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
#
# Kept, but no longer the only thing holding this up. conf.d/xwayland.lua now
# also sets the `Xft.dpi` X resource from the monitor scale, which is the
# general fix — Qt6 turns it into a devicePixelRatio on its own, so a new
# XWayland app no longer needs a wrapper of its own. And conf.d/env.lua asks Qt
# for `wayland;xcb`, which may well take Sioyek off XWayland entirely. Both
# variables are harmless in that case: QT_AUTO_SCREEN_SCALE_FACTOR is a Qt5 knob
# that Qt6 ignores, and QT_ENABLE_HIGHDPI_SCALING is already Qt6's default.
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
