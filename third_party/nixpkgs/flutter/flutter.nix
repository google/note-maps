{ channel, pname, version, sha256Hash, patches, dart
, dartPackages ? []
, filename ? "flutter_linux_${version}-${channel}.tar.xz"}:

{ bash, buildFHSUserEnv, cacert, coreutils, git, makeWrapper, runCommand, stdenv
, fetchurl, alsaLib, dbus, expat, libpulseaudio, libuuid, libX11, libxcb
, libXcomposite, libXcursor, libXdamage, libXfixes, libGL, nspr, nss
, symlinkJoin, systemd,tree }:

let
  drvName = "flutter-${channel}-${version}";
  flutter = stdenv.mkDerivation {
    name = "${drvName}-unwrapped";

    src = fetchurl {
      url =
        "https://storage.googleapis.com/flutter_infra/releases/${channel}/linux/${filename}";
      sha256 = sha256Hash;
    };

    buildInputs = [ makeWrapper git pub_cache ];

    inherit patches;

    postPatch = ''
      patchShebangs --build ./bin/
      find ./bin/ -executable -type f -exec patchelf --set-interpreter $(cat $NIX_CC/nix-support/dynamic-linker) {} \;
      mkdir -p ./bin/cache/pkg/sky_engine
      echo -e "name: sky_engine\nversion: 0.0.99\nauthor: Flutter Authors <flutter-dev@googlegroups.com>\ndescription: Dart SDK extensions for dart:ui\nhomepage: http://flutter.io\nenvironment:\n  sdk: '>=1.11.0 <3.0.0'\n" > ./bin/cache/pkg/sky_engine/pubspec.yaml
    '';

    buildPhase = ''
      FLUTTER_ROOT=$(pwd)
      FLUTTER_TOOLS_DIR="$FLUTTER_ROOT/packages/flutter_tools"
      SNAPSHOT_PATH="$FLUTTER_ROOT/bin/cache/flutter_tools.snapshot"
      STAMP_PATH="$FLUTTER_ROOT/bin/cache/flutter_tools.stamp"
      SCRIPT_PATH="$FLUTTER_TOOLS_DIR/bin/flutter_tools.dart"
      DART_SDK_PATH="$FLUTTER_ROOT/bin/cache/dart-sdk"

      DART="$DART_SDK_PATH/bin/dart"
      PUB="$DART_SDK_PATH/bin/pub"

      HOME=../.. # required for pub upgrade --offline, ~/.pub-cache
                 # path is relative otherwise it's replaced by /build/flutter
      export PUB_CACHE="${pub_cache}/libexec/pubcache"
      mkdir -p $DART_SDK_PATH
      cp -r ${dart}/* $DART_SDK_PATH

      (cd "$FLUTTER_TOOLS_DIR" && "$PUB" upgrade --offline)

      local revision="$(cd "$FLUTTER_ROOT"; git rev-parse HEAD)"
      "$DART" --snapshot="$SNAPSHOT_PATH" --packages="$FLUTTER_TOOLS_DIR/.packages" "$SCRIPT_PATH"
      echo "$revision" > "$STAMP_PATH"
      echo -n "${version}" > version

      rm -rf bin/cache/{artifacts,downloads}
      rm -f  bin/cache/*.stamp
    '';

    installPhase = ''
      mkdir -p $out
      cp -r . $out
    '';
  };

  # Wrap flutter inside an fhs user env to allow execution of binary,
  # like adb from $ANDROID_HOME or java from android-studio.
  fhsEnv = buildFHSUserEnv {
    name = "${drvName}-fhs-env";
    multiPkgs = pkgs: [
      # Flutter only use these certificates
      (runCommand "fedoracert" { } ''
        mkdir -p $out/etc/pki/tls/
        ln -s ${cacert}/etc/ssl/certs $out/etc/pki/tls/certs
      '')
      pkgs.zlib
    ];
    targetPkgs = pkgs:
      with pkgs; [
        bash
        curl
        dart
        git
        unzip
        which
        xz

        # flutter test requires this lib
        libGLU

        # for android emulator
        alsaLib
        dbus
        expat
        libpulseaudio
        libuuid
        libX11
        libxcb
        libXcomposite
        libXcursor
        libXdamage
        libXfixes
        libGL
        nspr
        nss
        systemd
      ];
  };

  # Create a Dart package for use with PUB_CACHE=$nix_profile/libexec/pubcache.
  dartPackage = { src, name ? "${src.name}", pubpath ? "hosted/pub.dartlang.org" }:
  stdenv.mkDerivation {
    inherit src name;
    preUnpack = ''
      mkdir $name
      cd $name
      sourceRoot=.
    '';
    installPhase = ''
      PUB_CACHE=$out/libexec/pubcache
      mkdir -p $PUB_CACHE/${pubpath}/${name}
      cp -r . $PUB_CACHE/${pubpath}/${name}
    '';
    #dontBuild = true;
  };

  # Create a Dart package from pub.dev
  fetchDartPackage = { name, version, sha256, pubpath ? "hosted/pub.dartlang.org", url ? "https://storage.googleapis.com/pub-packages/packages/${name}-${version}.tar.gz" }:
  dartPackage {
    src = fetchurl {
      name = baseNameOf (toString url); # TODO: hey, shouldn't this be the default or something? maybe it already is!
      inherit sha256 url;
    };
    name = "${name}-${version}";
  };

  mkPubCache = { dartPackages }:
    symlinkJoin { name="pub-cache"; paths=(builtins.map fetchDartPackage dartPackages); };

  pub_cache = mkPubCache { inherit dartPackages; };

in runCommand drvName {
  startScript = ''
    #!${bash}/bin/bash
    export PUB_CACHE=''${PUB_CACHE:-"$HOME/.pub-cache"}
    export ANDROID_EMULATOR_USE_SYSTEM_LIBS=1
    ${fhsEnv}/bin/${drvName}-fhs-env ${flutter}/bin/flutter --no-version-check "$@"
  '';
  preferLocalBuild = true;
  allowSubstitutes = false;
  passthru = { unwrapped = flutter; inherit mkPubCache; };
  meta = with stdenv.lib; {
    description = "Flutter is Google's SDK for building mobile, web and desktop with Dart";
    longDescription = ''
      Flutter is Google’s UI toolkit for building beautiful,
      natively compiled applications for mobile, web, and desktop from a single codebase.
    '';
    homepage = "https://flutter.dev";
    license = licenses.bsd3;
    platforms = [ "x86_64-linux" ];
    maintainers = with maintainers; [ babariviere ericdallo ];
  };
} ''
  mkdir -p $out/bin

  echo -n "$startScript" > $out/bin/${pname}
  chmod +x $out/bin/${pname}

  mkdir -p $out/bin/cache/dart-sdk/
  cp -r ${dart}/* $out/bin/cache/dart-sdk/
  ln $out/bin/cache/dart-sdk/bin/dart $out/bin/dart
''
