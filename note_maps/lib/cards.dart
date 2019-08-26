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
import 'package:provider/provider.dart';

import 'common_widgets.dart';
import 'mobileapi/controllers.dart';

class FutureText extends StatelessWidget {
  final Future<TextEditingController> futureTextController;
  final TextStyle style;

  FutureText(
    this.futureTextController, {
    this.style,
  });

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
            return ValueListenableBuilder<TextEditingValue>(
              valueListenable: snapshot.data,
              builder: (context, textEditingValue, _) => Text(
                textEditingValue.text,
                style: style,
                maxLines: null,
              ),
            );
          default:
            return CircularProgressIndicator();
        }
      },
    );
  }
}

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

class NameField extends StatelessWidget {
  final bool autofocus;

  NameField({this.autofocus = false});

  @override
  Widget build(BuildContext context) {
    var controller = Provider.of<NameController>(context);

    return ValueListenableBuilder<NameState>(
      valueListenable: controller,
      builder: (context, nameState, _) => ListTile(
        title: FutureTextField(
          controller.valueTextController,
          textCapitalization: TextCapitalization.words,
          style: Theme.of(context).textTheme.headline,
          autofocus: autofocus,
        ),
      ),
    );
  }
}

class OccurrenceField extends StatelessWidget {
  final bool autofocus;

  OccurrenceField({this.autofocus = false});

  @override
  Widget build(BuildContext context) {
    var controller = Provider.of<OccurrenceController>(context);
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, occurrenceState, _) => ListTile(
        title: FutureTextField(
          controller.valueTextController,
          textCapitalization: TextCapitalization.sentences,
          style: Theme.of(context).textTheme.body2,
          autofocus: autofocus,
        ),
      ),
    );
  }
}

class NameCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var controller = Provider.of<NameController>(context);
    return ValueListenableBuilder<NameState>(
      valueListenable: controller,
      builder: (context, nameState, _) => Card(
        child: ListTile(
          title: FutureText(
            controller.valueTextController,
            style: Theme.of(context).textTheme.headline,
          ),
          trailing: _noteMenuButton(context, controller),
        ),
      ),
    );
  }
}

class OccurrenceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var controller = Provider.of<OccurrenceController>(context);
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, occurrenceState, _) => Card(
        child: ListTile(
          title: FutureText(
            controller.valueTextController,
            style: Theme.of(context).textTheme.body2,
          ),
          trailing: _noteMenuButton(context, controller),
        ),
      ),
    );
  }
}

Widget _noteMenuButton(BuildContext context, NoteMapItemController controller) {
  return PopupMenuButton<NoteOption>(
    onSelected: (NoteOption choice) {
      switch (choice) {
        case NoteOption.delete:
          controller.delete().catchError((error) {
            Scaffold.of(context)
                .showSnackBar(SnackBar(content: Text(error.toString())));
            return null;
          });
          break;
      }
    },
    itemBuilder: (BuildContext context) => <PopupMenuEntry<NoteOption>>[
      const PopupMenuItem<NoteOption>(
        value: NoteOption.delete,
        child: Text('Delete'),
      ),
    ],
  );
}

enum NoteOption { delete }
enum RoleOption {
  editRole,
  editAssociation,
}
