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

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../controllers/controllers.dart';
import '../navigation.dart';
import '../widgets/widgets.dart';
import 'topic_tile.dart';

class BrowseSearchResults extends StatelessWidget {
  BrowseSearchResults({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SearchState>(
      valueListenable: Provider.of<SearchController>(context),
      builder: (context, SearchState searchState, _) => searchState.error !=
              null
          ? Container()
          : ListView.builder(
              itemCount: searchState.estimatedCount,
              itemBuilder: (context, index) => index < searchState.known.length
                  ? TopicProvider(
                      topicMapId: searchState.known[index].topicMapId,
                      topicId: searchState.known[index].id,
                      child: TopicTile(
                        onTap: () => Navigator.pushNamed(
                          context,
                          TopicPageArguments.routeName,
                          arguments: TopicPageArguments(
                              topicMapId: searchState.known[index].topicMapId,
                              topicId: searchState.known[index].id),
                        ),
                      ),
                    )
                  : Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
            ),
    );
  }
}
