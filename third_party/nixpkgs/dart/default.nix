{ stdenv, fetchurl, unzip, version ? "2.7.2" }:

let

  sources = let

    base = "https://storage.googleapis.com/dart-archive/channels";
    stable_version = "stable";
    beta_version = "beta";
    dev_version = "dev";
    x86_64 = "x64";
    i686 = "ia32";
    aarch64 = "arm64";

  in {
    "1.24.3-x86_64-darwin" = fetchurl {
      url = "${base}/${stable_version}/release/${version}/sdk/dartsdk-macos-${x86_64}-release.zip";
      sha256 = "1n4cq4jrms4j0yl54b3w14agcgy8dbipv5788jziwk8q06a8c69l";
    };
    "1.24.3-x86_64-linux" = fetchurl {
      url = "${base}/${stable_version}/release/${version}/sdk/dartsdk-linux-${x86_64}-release.zip";
      sha256 = "16sm02wbkj328ni0z1z4n4msi12lb8ijxzmbbfamvg766mycj8z3";
    };
    "1.24.3-i686-linux" = fetchurl {
      url = "${base}/${stable_version}/release/${version}/sdk/dartsdk-linux-${i686}-release.zip";
      sha256 = "0a559mfpb0zfd49zdcpld95h2g1lmcjwwsqf69hd9rw6j67qyyyn";
    };
    "1.24.3-aarch64-linux" = fetchurl {
      url = "${base}/${stable_version}/release/${version}/sdk/dartsdk-linux-${aarch64}-release.zip";
      sha256 = "1p5bn04gr91chcszgmw5ng8mlzgwsrdr2v7k7ppwr1slkx97fsrh";
    };
    "2.7.2-x86_64-darwin" = fetchurl {
      url = "${base}/${stable_version}/release/${version}/sdk/dartsdk-macos-${x86_64}-release.zip";
      sha256 = "111zl075qdk2zd4d4mmfkn30jmzsri9nq3nspnmc2l245gdq34jj";
    };
    "2.7.2-x86_64-linux" = fetchurl {
      url = "${base}/${stable_version}/release/${version}/sdk/dartsdk-linux-${x86_64}-release.zip";
      sha256 = "0vvsgda1smqdjn35yiq9pxx8f5haxb4hqnspcsfs6sn5c36k854v";
    };
    "2.7.2-i686-linux" = fetchurl {
      url = "${base}/${stable_version}/release/${version}/sdk/dartsdk-linux-${i686}-release.zip";
      sha256 = "0dj01d2wwrp3cc5x73vs6fzhs6db60gkbjlrw3w9j04wcx69i38m";
    };
    "2.7.2-aarch64-linux" = fetchurl {
      url = "${base}/${stable_version}/release/${version}/sdk/dartsdk-linux-${aarch64}-release.zip";
      sha256 = "1p66fkdh1kv0ypmadmg67c3y3li3aaf1lahqh2g6r6qrzbh5da2p";
    };
    "2.10.0-x86_64-darwin" = fetchurl {
      url = "${base}/${stable_version}/release/${version}/sdk/dartsdk-macos-${x86_64}-release.zip";
      sha256 = "1n4qgsax5wi7krgvvs0dy7fz39nlykiw8gr0gdacc85hgyhqg09j";
    };
    "2.10.0-x86_64-linux" = fetchurl {
      url = "${base}/${stable_version}/release/${version}/sdk/dartsdk-linux-${x86_64}-release.zip";
      sha256 = "0dncmsfbwcn3ygflhp83i6z4bvc02fbpaq1vzdzw8xdk3sbynchb";
    };
    "2.9.0-4.0.dev-x86_64-darwin" = fetchurl {
      url = "${base}/${dev_version}/release/${version}/sdk/dartsdk-macos-${x86_64}-release.zip";
      sha256 = "0gj91pbvqrxsvxaj742cllqha2z65867gggzq9hq5139vkkpfj9s";
    };
    "2.9.0-4.0.dev-x86_64-linux" = fetchurl {
      url = "${base}/${dev_version}/release/${version}/sdk/dartsdk-linux-${x86_64}-release.zip";
      sha256 = "16d9842fb3qbc0hy0zmimav9zndfkq96glgykj20xssc88qpjk2r";
    };
    "2.9.0-4.0.dev-i686-linux" = fetchurl {
      url = "${base}/${dev_version}/release/${version}/sdk/dartsdk-linux-${i686}-release.zip";
      sha256 = "105wgyxmi491c7qw0z3zhn4lv52h80ngyz4ch9dyj0sq8nndz2rc";
    };
    "2.9.0-4.0.dev-aarch64-linux" = fetchurl {
      url = "${base}/${dev_version}/release/${version}/sdk/dartsdk-linux-${aarch64}-release.zip";
      sha256 = "1x6mlmc4hccmx42k7srhma18faxpxvghjwqahna80508rdpljwgc";
    };
    "2.11.0-161.0.dev-x86_64-darwin" = fetchurl {
      url = "${base}/${dev_version}/release/${version}/sdk/dartsdk-macos-${x86_64}-release.zip";
      sha256 = "0mlwxp7jkkjafxkc4vqlgwl62y0hk1arhfrvc9hpm9dv98g3bdjj";
    };
    "2.11.0-161.0.dev-x86_64-linux" = fetchurl {
      url = "${base}/${dev_version}/release/${version}/sdk/dartsdk-linux-${x86_64}-release.zip";
      sha256 = "05difz4w2fyh2yq5p5pkrqk59jqljlxhc1i6lmy5kihh6z69r12i";
    };
    #"2.10.4-x86_64-darwin" = fetchurl { } # TODO
    "2.10.4-x86_64-linux" = fetchurl {
      url = "${base}/${stable_version}/release/${version}/sdk/dartsdk-linux-${x86_64}-release.zip";
      sha256 = "0pjqj2bsliq13q8b2mk2v07w4vzjqcmr984ygnwv5kx0dp5md7vq";
    };
    #"2.12.0-133.2.beta-x86_64-darwin" = fetchurl { } # TODO
    "2.12.0-133.2.beta-x86_64-linux" = fetchurl {
      url = "${base}/${beta_version}/release/${version}/sdk/dartsdk-linux-${x86_64}-release.zip";
      sha256 = "1nq17p6g96xwc9nbnq54b4z22kn7cgzi5l408nxs33m7iinz0fgq";
    };
    "2.12.0-133.0.dev-x86_64-darwin" = fetchurl {
      url = "${base}/${dev_version}/release/${version}/sdk/dartsdk-macos-${x86_64}-release.zip";
      sha256 = "04c8zlw9c29lqpsdz48gcpl6nh9rb0qcgiy4yhc040n16a3qcx05";
    };
    "2.12.0-133.0.dev-x86_64-linux" = fetchurl {
      url = "https://storage.googleapis.com/flutter_infra/flutter/4797b066524201e86d6bc5c110104c390899f264/dart-sdk-linux-${x86_64}.zip";
      sha256 = "0000000000000000000000000000000000000000000000000000";
    };
  };

in

with stdenv.lib;

stdenv.mkDerivation {

  pname = "dart";
  inherit version;

  nativeBuildInputs = [
    unzip
  ];

  src = sources."${version}-${stdenv.hostPlatform.system}" or (throw "unsupported version/system: ${version}/${stdenv.hostPlatform.system}");

  installPhase = ''
    mkdir -p $out
    cp -R * $out/
    echo $libPath
    find $out/bin -executable -type f -exec patchelf --set-interpreter $(cat $NIX_CC/nix-support/dynamic-linker) {} \;
  '';

  libPath = makeLibraryPath [ stdenv.cc.cc ];

  dontStrip = true;

  meta = {
    homepage = "https://www.dartlang.org/";
    maintainers = with maintainers; [ grburst ];
    description = "Scalable programming language, with robust libraries and runtimes, for building web, server, and mobile apps";
    longDescription = ''
      Dart is a class-based, single inheritance, object-oriented language
      with C-style syntax. It offers compilation to JavaScript, interfaces,
      mixins, abstract classes, reified generics, and optional typing.
    '';
    platforms = [ "x86_64-linux" "i686-linux" "aarch64-linux" "x86_64-darwin" ];
    license = licenses.bsd3;
  };
}
