# BUILD

To build the AAR and JAR files:

    gomobile bind \
      -target=android \
      -o note_maps/android/mobileapi/mobileapi.aar \
      github.com/google/note-maps/store/mobileapi

To regenerate the Dart protocol buffer code, make sure `dart` and `protoc-gen-dart` are available on `$PATH`. See [Dart Generated Code][] for more details.

[Dart Generated Code]: https://developers.google.com/protocol-buffers/docs/reference/dart-generated

    protoc \
      --dart_out=note_maps/lib/mobileapi \
      store/pb/pb.proto
