# Google Sans, vendored from the official OFL release on fonts.google.com
# (not in nixpkgs — only googlesans-code, the monospace sibling, is).
#
# noctalia's config.toml references two distinct family names:
#   font_family = "Google Sans"         -> GoogleSans-*.ttf
#   font_family = "Google Sans Medium"  -> GoogleSans-Medium.ttf carries this
#                                          as a secondary family name for apps
#                                          that pick a family instead of a
#                                          weight.
# The static family covers both; the variable-font build in the same zip
# does not expose the "Google Sans Medium" family, so it will not work here.
# 17pt optical-size statics are dropped as redundant duplicates.
{
  stdenvNoCC,
  lib,
}:
stdenvNoCC.mkDerivation {
  pname = "google-sans";
  version = "1.0";

  src = ./fonts/google-sans;

  installPhase = ''
    runHook preInstall
    install -Dm644 static/*.ttf -t $out/share/fonts/truetype/google-sans
    install -Dm644 OFL.txt -t $out/share/doc/google-sans
    runHook postInstall
  '';

  meta = {
    description = "Google Sans font family (official OFL release)";
    homepage = "https://fonts.google.com/specimen/Google+Sans";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
}
