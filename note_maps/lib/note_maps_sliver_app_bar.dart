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

import 'dart:ui';

import 'package:flutter/material.dart';

import 'item_icon.dart';

// NoteMapsSliverAppBar just reduces boilerplate when re-using SliverAppBar
// across the NoteMaps app.
//
// Composition should still be preferred over inheritance, but a
// CustomScrollView requires that all its children by Sliver-based widgets.
// Inheritance is used here just to make sure the resulting Widget will meet
// CustomScrollView's requirements.
class NoteMapsSliverAppBar extends SliverAppBar {
  NoteMapsSliverAppBar({
    Key key,
    @required Orientation orientation,
    @required Widget title,
    List<Widget> actions,
    dynamic item,
    Color color,
  })  : assert(orientation != null),
        assert(title != null),
        super(
          key: key,
          pinned: true,
          snap: false,
          floating: false,
          actions: actions,
          expandedHeight: orientation == Orientation.portrait ? 160.0 : null,
          flexibleSpace: FlexibleSpaceBar(
            title: title,
            background: item == null
                ? null
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      ItemIcon(
                        item,
                        fit: BoxFit.fitWidth,
                        alignment: Alignment.topCenter,
                      ),
                      BackdropFilter(
                        filter:
                            new ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                        child: new Container(
                          decoration: new BoxDecoration(
                            color: color.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        );
}
