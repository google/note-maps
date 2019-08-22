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

import 'package:note_maps/app_navigation_bloc.dart';
import 'package:note_maps/library_page/library_navigator.dart';
import 'package:note_maps/mobileapi/mobileapi.dart';

class AppNavigationStack extends StatefulWidget {
  final QueryApi queryApi;
  final CommandApi commandApi;

  AppNavigationStack({
    Key key,
    @required this.queryApi,
    @required this.commandApi,
  }) : super(key: key);

  @override
  State<AppNavigationStack> createState() => _AppNavigationStackState();
}

class _AppNavigationStackState extends State<AppNavigationStack>
    with TickerProviderStateMixin<AppNavigationStack> {
  AppNavigationBloc appNavigationBloc;
  List<GlobalKey<NavigatorState>> keys;
  List<AnimationController> faders;

  @override
  void initState() {
    super.initState();
    appNavigationBloc = BlocProvider.of<AppNavigationBloc>(context);
    keys = AppNavigationPage.values
        .map((_) => GlobalKey<NavigatorState>())
        .toList();
    faders = AppNavigationPage.values.map((_) {
      return AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 200),
      );
    }).toList();
  }

  @override
  void dispose() {
    appNavigationBloc.dispose();
    for (AnimationController controller in faders) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AppNavigationBloc>(
      builder: (context) => appNavigationBloc,
      child: BlocBuilder<AppNavigationBloc, AppNavigationState>(
        builder: (context, state) {
          return WillPopScope(
            onWillPop: () async =>
                !await keys[state.page.index].currentState.maybePop(),
            child: Stack(
              fit: StackFit.expand,
              children: AppNavigationPage.values.map((page) {
                Widget screen;
                switch (page) {
                  case AppNavigationPage.trash:
                    screen = LibraryNavigator(navigatorKey: keys[page.index]);
                    break;
                  default:
                    screen = LibraryNavigator(navigatorKey: keys[page.index]);
                    break;
                }
                final Widget transition = FadeTransition(
                  opacity: faders[page.index]
                      .drive(CurveTween(curve: Curves.fastOutSlowIn)),
                  child: screen,
                );
                if (page == state.page) {
                  faders[page.index].forward();
                  return transition;
                } else {
                  faders[page.index].reverse();
                  if (faders[page.index].isAnimating) {
                    return IgnorePointer(child: transition);
                  }
                  return Offstage(child: transition);
                }
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
