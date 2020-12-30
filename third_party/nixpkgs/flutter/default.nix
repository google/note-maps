{ callPackage, dart, lib, stdenvNoCC }:

let
  dart_stable = dart.override { version = "2.10.4"; };
  dart_beta = dart.override { version = "2.12.0-133.2.beta"; };
  dart_dev = dart.override { version = "2.12.0-133.0.dev"; };
  mkFlutter = opts: callPackage (import ./flutter.nix opts) { };
  getPatches = dir:
    let files = builtins.attrNames (builtins.readDir dir);
    in map (f: dir + ("/" + f)) files;
in {
  mkFlutter = mkFlutter;
  stable = mkFlutter rec {
    pname = "flutter";
    channel = "stable";
    version = "1.22.5";
    filename = "flutter_linux_${version}-${channel}.tar.xz";
    sha256Hash
      = lib.optionalString (stdenvNoCC.isLinux) "1dv5kczcj9npf7xxlanmpc9ijnxa3ap46521cxn14c0i3y9295ja"
      + lib.optionalString (stdenvNoCC.isDarwin) "0000000000000000000000000000000000000000000000000000"
      ;
    patches = getPatches ./patches/stable;
    dart = dart_stable;
    dartPackages = import ./stable.nix;
  };
  beta = mkFlutter rec {
    pname = "flutter";
    channel = "beta";
    version = "1.25.0-8.1.pre";
    sha256Hash
      = lib.optionalString (stdenvNoCC.isLinux) "01rfs7n3ghaffqrjq44libgb1iyrr1h2br995inf1l6vqi78mcld"
      + lib.optionalString (stdenvNoCC.isDarwin) "0000000000000000000000000000000000000000000000000000"
      ;
    patches = getPatches ./patches/dev;
    dart = dart_beta;
    dartPackages = import ./beta.nix;
  };
  dev = mkFlutter rec {
    pname = "flutter";
    channel = "dev";
    version = "1.25.0-8.0.pre";
    sha256Hash
      = lib.optionalString (stdenvNoCC.isLinux) "0000000000000000000000000000000000000000000000000000"
      + lib.optionalString (stdenvNoCC.isDarwin) "0aay3ynfrfajgmqmjzrgvvf3nv36q5dl5073flpjnvprl1h890z4"
      ;
    patches = getPatches ./patches/dev;
    dart = dart_dev;
    dartPackages = import ./dev.nix;
  };
}
