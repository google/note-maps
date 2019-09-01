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
import 'package:flutter/services.dart';

import 'error_indicator.dart';

class FutureTextField extends StatelessWidget {
  final Future<TextEditingController> futureTextController;
  final bool autofocus;
  final TextCapitalization textCapitalization;
  final TextStyle style;
  FocusNode _focusNode;

  FutureTextField(
    this.futureTextController, {
    this.autofocus = false,
    this.textCapitalization,
    this.style,
    FocusNode focusNode,
  }) {
    _focusNode = focusNode ?? FocusNode();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TextEditingController>(
      future: futureTextController,
      initialData: null,
      builder: (_, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.done:
            if (snapshot.hasError) {
              return ErrorIndicator();
            }
            return TextField(
              controller: snapshot.data,
              autofocus: autofocus,
              //focusNode: FocusNode(),
              style: style,
              textCapitalization: textCapitalization,
              //decoration: InputDecoration(border: InputBorder.none),
              maxLines: null,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) {
                //print("attempting to switch focus");
                //print(DefaultFocusTraversal.of(context).next(_focusNode));
                bool traversed = FocusScope.of(context).nextFocus();
                print("traversed focus: ${traversed}");
              },
            );
          default:
            return CircularProgressIndicator();
        }
      },
    );
  }
}
