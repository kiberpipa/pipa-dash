# WARNING: this is written badly, do not use it unless desperate

{ pkgs ? import <nixpkgs> {} }:
pkgs.stdenv.mkDerivation {
  name = "pipa-dash";
  src = { outPath = ./.; name = "pipa-dash-src"; };
  buildInputs = with pkgs; [ nodejs nodePackages.npm nodePackages.bower rubygems
    git makeWrapper ];
  unpackPhase = ''
    mkdir -p $out/var/node_modules
    mkdir -p $out/home
    cp -r $src/* $out/var
    cd $out/var
  '';
  buildPhase = ''
    substituteInPlace $out/var/Gruntfile.js \
      --replace "  'open'," "" \
      --replace ".tmp" "/tmp/pipa-dash" \
      --replace \
        "loadPath: 'bower_components'" \
        "loadPath: 'bower_components', cacheLocation: '/tmp/pipa-dash/sass-cache'"

    export CI=true
    export HOME=$out/home
    export NPM_PACKAGES="$HOME/.npm-packages"
    export NODE_PATH="$NPM_PACKAGES/lib/node_modules:$out/var/node_modules"
    export PATH="$NPM_PACKAGES/bin:$PATH"
    export GEM_HOME=$HOME/.gems
    export SSL_CERT_FILE=${pkgs.cacert}/etc/ca-bundle.crt

    gem install sass
    npm install
    npm install grunt-cli
    bower install
  '';
  installPhase = ''
    makeWrapper $out/var/node_modules/.bin/grunt $out/bin/pipa-dash \
      --run "cd $out/var" \
      --run "mkdir -p /tmp/pipa-dash" \
      --prefix "GEM_HOME" ":" "$out/home/.gems" \
      --prefix "PATH" ":" "${pkgs.ruby}/bin:$out/home/.gems/bin:$out/var/node_modules/.bin" \
      --add-flags "serve --force"
  '';
}
