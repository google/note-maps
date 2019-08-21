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
import 'package:flutter_bloc/flutter_bloc.dart';

import 'topic_identicon.dart';
import 'topic_bloc.dart';

// TopicTabBar provides something resembling a tab bar with the assumption that
// each tab represents a topic in a topic map, and allowing that the set of
// topics may be very long.
//
// Implementing PreferredSizeWidget is necessary in order for TopicTabBar to
// work as a value for AppBar.bottom, and PreferredSizeWidget includes a build
// method, so TopicTabBar has to have a build method too. Since that implies
// it's a StatelessWidget, this class attempts to avoid confusion by just
// extending StatelessWidget even though a StatefulWidget would be more natural.
class TopicTabBar extends StatelessWidget implements PreferredSizeWidget {
  final _TopicTabBar _child;

  TopicTabBar({
    Key key,
    @required TextTheme textTheme,
  })  : _child = _TopicTabBar(textTheme: textTheme),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return child;
  }

  @override
  Widget get child => _child;

  @override
  Size get preferredSize => Size(360, _child.preferredHeight);
}

class _TopicTabBar extends StatelessWidget {
  // According to https://material.io/design/components/tabs.html#spec, a tab
  // bar should have 12dp vertical padding at top and bottom as well as a 2dp
  // thick line below the padding to indicate the active line.
  static const double _verticalPadding = 12.0;
  static const double _activeLineHeight = 2.0;
  static const double _iconSize = 48.0;
  static const double _iconTextPadding = 6.0;

  // This is just an alignment hack, there is probably a better way. The goal is
  // to keep the bottom border on the centered selected topic aligned with the
  // bottom border on the text fields associated with name and note values.
  static const double _additionalHorizontalPadding = 4.0;

  // From https://material.io/design/components/tabs.html, it looks like a tab
  // bar is supposed to use the "button" style text for tab labels. That
  // knowledge should be encoded within this class, but we still need a given
  // TextTheme to determine the height of button text.
  final TextTheme textTheme;
  final Color color;

  _TopicTabBar({@required this.textTheme})
      : assert(textTheme != null),
        color = textTheme.button.color;

  double get preferredHeight =>
      textTheme.button.fontSize +
      _iconSize +
      _iconTextPadding +
      _verticalPadding * 2 +
      _activeLineHeight;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TopicBloc, TopicState>(
      bloc: BlocProvider.of<TopicBloc>(context),
      builder: (context, state) => Row(
        children: <Widget>[
          IconButton(
            icon: Icon(
              Icons.chevron_left,
              color: color,
            ),
          ),
          Container(width: _additionalHorizontalPadding),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: textTheme.button.color,
                    width: _activeLineHeight,
                  ),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  children: <Widget>[
                    TopicIdenticon(
                      state.viewModel.topic,
                      size: _iconSize,
                      backgroundColor: Theme.of(context).primaryColorLight,
                    ),
                    Container(width: 0, height: _iconTextPadding),
                    Text(
                      state.viewModel.nameNotice + state.viewModel.name,
                      style: textTheme.button,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(width: _additionalHorizontalPadding),
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
