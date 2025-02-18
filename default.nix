{ stdenv, fetchYarnDeps, fixup_yarn_lock, nodejs }:

# I can't use mkYarnPackage here because it calls "yarn install" with
# "--ignore-scripts". the vue-demi library won't work unless its postinstall
# script is run.
#
# mkYarnModules has an ignoreScripts argument, but it isn't exposed on
# mkYarnPackage.
#
# This approach is cribbed from:
# https://github.com/NixOS/nixpkgs/blob/25b33e9c7040986ba1b3ae4c8873543f88b57258/pkgs/applications/misc/tandoor-recipes/frontend.nix
stdenv.mkDerivation rec {
  name = "airsonic-refix-jukebox";
  src = ./.;

  yarnOfflineCache = fetchYarnDeps {
    yarnLock = "${src}/yarn.lock";
    hash = "sha256-RjniI8ZVGv7i1ec6cR1ssm+wcVyO4nXOG7/rNwd6YLY=";
  };

  nativeBuildInputs = [
    fixup_yarn_lock
    nodejs
    nodejs.pkgs.yarn
  ];

  configurePhase = ''
    runHook preConfigure

    export HOME=$(mktemp -d)
    yarn config --offline set yarn-offline-mirror "$yarnOfflineCache"
    fixup_yarn_lock yarn.lock
    command -v yarn
    yarn install --frozen-lockfile --offline --no-progress --non-interactive
    patchShebangs node_modules/

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    yarn --offline run build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    cp -R dist/ $out

    runHook postInstall
  '';
}
