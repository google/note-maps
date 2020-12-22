# Note Maps: Reproducible Builds & Continuous Integration

Reproducible builds and continuous integration are work in progress for Note
Maps. This doc describes the status quo.

## Requirements

Support:

*   Go
*   Dart
*   Flutter

Run on:

*   Linux
*   OSX
*   Windows (eventually)

## Solution

### Nix where possible

Nix is used to collect consistent versions of tools required to build the app.

Nix is a neat implementation of reproducible builds, atomic upgrades, and
project-specific build environments. However, installing Nix on an existing
Linux or OSX machine is quite a chore for someone who just wants to build Note
Maps. The work-around is to install each of the required build tools
manually.

Nix struggles a bit to support complex SDKs like Flutter or Android Studio. The
problems are all solveable, there are people working on them, it's getting
better, but they're not solved yet.

Finally, Nix is only meant to integrate with tools like GNU Make or Bazel, not
to replace them.

### GNU Make for the rest

Nix is used to setup the build environment, including a consistent version of
GNU Make. The rest of the build is orchestrated with a Makefile.

## Alternatives

### Bazel

Bazel is a neat solution to support reproducible builds. It's supported by
Google, which also supports Go, Dart, and Flutter, so it's reasonable to expect
using them in combination to be fairly straightforward.

However, making Bazel work with Flutter and Dart proved quite a challenge.
Even working with Go is not exactly easy. Bazel doesn't even allow build
actions that directly modify the source tree. Dart, Flutter, and Go all have
some support for code generation that conventionally _does_ modify the source
tree. There are solutions and work-arounds that can get pretty close to good
enough, and maybe some day these will be easy enough to make Bazel worth the
trouble.

### Docker

Docker is a popular solution to the reproducible builds challenge.

However, it can only run binaries in a Linux or Windows environment. Building
iOS or MacOS apps requires running Docker on OSX itself (not in a Linux virtual
machine running on OSX).
