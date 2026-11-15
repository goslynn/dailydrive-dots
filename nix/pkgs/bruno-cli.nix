# bru (Bruno CLI), tracking npm's @usebruno/cli instead of nixpkgs' bruno-cli.
#
# nixpkgs' bruno-cli package builds the bruno-cli *workspace* out of the
# monorepo tag that matches the Bruno app's release (e.g. v4.0.0), but that
# workspace is versioned independently of the app and lagged behind at
# 1.16.0 there. @usebruno/cli on npm is already past 4.x, so this pulls the
# published package directly instead of waiting for nixpkgs to catch up.
#
# package-lock.json is pre-generated (`npm install --package-lock-only`
# against the published package.json) since the npm tarball ships without
# one; buildNpmPackage needs it to compute npmDepsHash reproducibly.
{
  lib,
  buildNpmPackage,
  fetchurl,
}:
buildNpmPackage rec {
  pname = "bruno-cli";
  version = "4.2.1";

  src = fetchurl {
    url = "https://registry.npmjs.org/@usebruno/cli/-/cli-${version}.tgz";
    hash = "sha512-1QKLVBWTsT02+aqgkZFjFLdrqSftId1E6ElGiExdmflygGQ6cdSqEiWanvPQlK31yA5ukd7abcbCGfebiGnscQ==";
  };

  postPatch = ''
    cp ${./bruno-cli/package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-aUtFcYAw8fol4LIOtY4S0ng2Ajc7+US+iPHdRn+sDac=";

  npmFlags = [ "--legacy-peer-deps" ];
  dontNpmBuild = true;

  meta = {
    description = "CLI for Bruno, the open-source API client (tracks npm's @usebruno/cli directly)";
    homepage = "https://www.usebruno.com";
    license = lib.licenses.mit;
    mainProgram = "bru";
  };
}
