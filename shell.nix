{ useClang ? false, crossSystem ? null }:

let
  pkgsSrc = builtins.fetchTarball https://github.com/NixOS/nixpkgs-channels/archive/nixos-19.09.tar.gz;
  cross_overlays = [
    (self: super: { nghttp2_static = super.nghttp2.overrideAttrs (old: { configureFlags = old.configureFlags ++ [ "--enable-static" "--disable-shared" "CFLAGS=-DNGHTTP2_STATICLIB"]; }); })
    (self: super: { curl_static = super.curl.overrideAttrs (old: { configureFlags = old.configureFlags ++ [ "--enable-static" "--disable-shared" "CFLAGS=-DNGHTTP2_STATICLIB"]; }); })
  ];
  overlays = [
    #(self: super: {
    #  windows = (super.windows or {}) // {
    #    mcfgthreads = super.windows.mcfgthreads.overrideAttrs
    #    (old: {
    #      configureFlags = (old.configureFlags or []) ++ [ "--enable-static" "--disable-shared"];
    #    });
    #  };
    #})
  ];
in

with import pkgsSrc { inherit crossSystem; crossOverlays = cross_overlays; inherit overlays; };

with import ./release-common.nix { inherit pkgs; };

(if useClang then clangStdenv else stdenv).mkDerivation {
  name = "nix";

  nativeBuildInputs = nativeBuildDeps ++ tarballDeps;

  buildInputs = buildDeps
   ++ lib.optionals (!stdenv.hostPlatform.isWindows) perlDeps;

  inherit mesonFlags configureFlags;

  enableParallelBuilding = true;

  installFlags = "sysconfdir=$(out)/etc";

  shellHook =
    ''
      export prefix=$(pwd)/inst
      configureFlags+=" --prefix=$prefix"
      PKG_CONFIG_PATH=$prefix/lib/pkgconfig:$PKG_CONFIG_PATH
      PATH=$prefix/bin:$PATH
    '';
}
