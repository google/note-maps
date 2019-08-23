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
import 'package:provider/provider.dart';

import 'mobileapi/controllers.dart';

class NameCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var controller = Provider.of<NameController>(context);
    return ValueListenableBuilder<NameState>(
      valueListenable: controller,
      builder: (context, nameState, _) => Card(
        child: Row(
          children: <Widget>[
            Container(width: 48),
            Expanded(
              child: TextField(
                textCapitalization: TextCapitalization.words,
                autofocus: true,
                style: Theme.of(context).textTheme.title,
                decoration: InputDecoration(border: InputBorder.none),
              ),
            ),
            _noteMenuButton(),
          ],
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
        child: Row(
          children: <Widget>[
            Container(width: 48),
            Expanded(
              child: TextField(
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(border: InputBorder.none),
              ),
            ),
            _noteMenuButton(),
          ],
        ),
      ),
    );
  }
}

Widget _noteMenuButton() {
  return PopupMenuButton<NoteOption>(
    onSelected: (NoteOption choice) {},
    itemBuilder: (BuildContext context) => <PopupMenuEntry<NoteOption>>[
      const PopupMenuItem<NoteOption>(
        value: NoteOption.delete,
        child: Text('Delete note'),
      ),
    ],
  );
}

enum NoteOption { delete }
enum RoleOption {
  editRole,
  editAssociation,
}
