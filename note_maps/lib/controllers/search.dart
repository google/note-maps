// Copyright 2019 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../mobileapi/mobileapi.dart';

class SearchState {
  final int estimatedCount;
  final List<NoteMapKey> known;
  final Error error;

  const SearchState.prime()
      : estimatedCount = 1,
        known = const [],
        error = null;

  SearchState.partial(List<NoteMapKey> known)
      : estimatedCount = known.length + 1,
        known = known.toList(growable: false),
        error = null;

  SearchState.complete(List<NoteMapKey> known)
      : estimatedCount = known.length,
        known = known.toList(growable: false),
        error = null;

  SearchState.error(Error error)
      : estimatedCount = 0,
        known = const [],
        error = error;
}

class SearchController extends ValueListenable<SearchState> {
  final NoteMapRepository repository;
  final Int64 topicMapId;
  final ValueNotifier<SearchState> _valueNotifier;

  SearchController({this.repository, this.topicMapId})
      : assert(repository != null),
        assert(topicMapId != null && topicMapId != Int64(0)),
        _valueNotifier = ValueNotifier(SearchState.prime());

  Future<void> load() async {
    await repository.search(topicMapId).then((noteMapKeys) {
      print("search result: ${noteMapKeys.length}");
      _valueNotifier.value = SearchState.complete(noteMapKeys);
    }).catchError((error) {
      print("search error: ${error}");
      return _valueNotifier.value = SearchState.error(error);
    });
  }

  @override
  void addListener(listener) => _valueNotifier.addListener(listener);

  @override
  void removeListener(listener) => _valueNotifier.removeListener(listener);

  @override
  SearchState get value => _valueNotifier.value;
}
