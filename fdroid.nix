{ project ? import ./nix { }, pkgs ? project.pkgs }:
let
  imageDigest = "sha256:4e8103258a3a033d27809f202dc0aecb00f9f80b9a2744362415b08629cff375";
  image = pkgs.dockerTools.pullImage {
    imageName = "registry.gitlab.com/fdroid/docker-executable-fdroidserver";
    imageDigest = "sha256:4e8103258a3a033d27809f202dc0aecb00f9f80b9a2744362415b08629cff375";
    sha256 = "04n3s403kbkilkb1sisx1ja2iqvjzhy300dhmyy4w9zdwsla5zfv";
    finalImageName = "registry.gitlab.com/fdroid/docker-executable-fdroidserver";
    finalImageTag = "master";
    os = "linux";
    arch = "x86_64";
  };
  # docker image inspect ${imageDigest} || docker load < ${image}
  fdroid = pkgs.writeShellScriptBin "fdroid" ''
    docker run --rm \
      -u $(id -u):$(id -g) \
      -v ${pkgs.androidsdk}/libexec/android-sdk:/opt/android-sdk \
      -e ANDROID_HOME:/opt/android-sdk \
      -v ${pkgs.jdk}:/opt/jdk \
      -e JAVA_HOME:/opt/jdk \
      -v $(pwd):/repo \
      registry.gitlab.com/fdroid/docker-executable-fdroidserver:master \
      "$@"
  '';
in project.pkgs.mkShell {
  buildInputs = [ fdroid ];
}
