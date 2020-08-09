# Note Maps: Design

## Objective

> Suppose you could have a note taking app that's also a personal database and
> works a bit like a structured document editor. Sound interesting?
>
> What if this note taking app is also offline-first, peer-to-peer replicated,
> collaborative, and encrypted on the wire in a way that lets untrusted peers
> be trusted for replicated storage?
>
> [2020-05-15](https://twitter.com/joshuatacoma/status/1261254734327025669)

Describe how to make this a reality.  Describe how the [requirements][] can be
met.

[requirements]: requirements.md

## Alternative Dependencies

FRs 1 through 6 can be met with almost any combination of technologies that
will help with the tricker URs and TRs. We need to sort out that combination
first.

UR2 is the most complex requirement and requires a "rich text editor" component
that supports deep customization.  That one requirement already limits the
options.  A proof-of-concept for UR2 was already implemented with [QuillJS][],
which is an HTML/JS/CSS component.  QuillJS is being reimplemented for
[Flutter][] in the [Zefyr Editor][] project.  These are the only two solutions
I'm aware of right now (2020-08-08).  QuillJS is certainly the more stable
of the two.

* Use [QuillJS][] with an HTML-based solution like [Electron][]
* Use [QuillJS][] with a solution that supports embedding and interacting with
  an HTML view.
* Use [Zefyr Editor][] with [Flutter][].

UR4, TR4, and TR5 will be easier to meet with tools that already implement many
best practices across mobile and desktop platforms. For example:

* [Flutter][] apps can look the same wherever they run, and Flutter has its own
  cross-platform guidelines. Flutter support for desktop apps seemed to be
  lagging a year ago but [recent Flutter Desktop developments][] show this is
  changing. Go code be packaged in a Flutter plugin for Linux or MacOS just as
  it can for Android or iOS, and right now (2020-08-08) flutter.dev/desktop
  reports that Windows platform support is under development.
* [React Native][] works with native UI components on all platforms, so might
  be better suited than Flutter to deal with some platform-specific edge cases.
  However, using QuillJS in React Native requires a WebView wrapper, which
  seems a bit silly since it'll be center of the UI.
* [Electon][] for desktop, [Cordova][] for mobile, and one or more of the many
  (many) web UI frameworks for HTML/JS/CSS apps. Also one of the many build
  systems, unit test libraries, and versions of JavaScript. I mean ECMAScript.

For TR1, TR2, and TR3, I'll be using [ThreadsDB][] because it's the only
solution that takes care of all these concerns.  However, it's an open question
whether each running Note Maps app will:

* Be its own peer.
  * However, this is an unconventional way to use ThreadsDB that may introduce
    more surprising challenges.
* Use a nearby peer like FleekHQ's [Space Daemon][], a shared peer like
  TextileIO's [Hub][], or run a separate set of peers as a part of a service
  just for Note Maps.
  * However, this may compromise TR3, requiring network access for basic
    operations.

[Electron]: https://www.electronjs.org/
[Flutter]: https://flutter.dev/
[Hub]: https://docs.textile.io/hub/
[QuillJS]: https://quilljs.com/
[React Native]: https://reactnative.dev/
[Space Daemon]: https://docs.fleek.co/space-daemon/overview/
[ThreadsDB]: https://docs.textile.io/threads/
[Zefyr Editor]: https://zefyr-editor.gitbook.io/
[recent Flutter Desktop developments]: https://medium.com/flutter/flutter-and-desktop-3a0dd0f8353e

## Overview

[Zefyr Editor][] will be used with [Flutter][] to produce an app that will work
on Android, iOS, MacOS, Linux, and eventually Windows.  The plugin bridge will
use simple byte slices to encode protos to and from the Go code, and this
bridge will be re-implemented for each platform.  [ThreadsDB][] will be used to
make the app itself a peer, with other connectivity options in the future.

* risk: Zefyr Editor might not work well enough soon enough.
  * mitigation: accept this while it gets better.
  * mitigation: help out on the Zefyr Editor project.
* risk: the number of supported platforms is too large to test.
  * mitigation: use one or more of the many available continuous integration
    services already available to mostly build each pushed ref for all
    platforms, and to fully build each release for all platforms.
* risk: making each app a ThreadsDB peer causes problems.
  * mitigation: add other connectivity options like [Hub][] or
    [Space Daemon][], then disable the "embedded peer" option for affected
    platforms.

## Plan

1. Refactor or rewrite existing Flutter UI around Zefyr.
1. Refactor or rewrite existing Flutter plugin to share information about
   ThreadsDB: connection status, presence of local data, etc.
   * Use code generation where possible.
   * Show this information in the Flutter UI.
1. Refactor or rewrite existing Flutter plugin to read and write in terms of
   diffs.
   * Use code generation where possible.
1. Do the main work of implementing UR2 and the FRs to produce a useful app.
1. Share widely for feedback.
