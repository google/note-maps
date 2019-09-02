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

import '../controllers/controllers.dart';

class OccurrenceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var controller = Provider.of<OccurrenceController>(context);
    return ValueListenableBuilder<OccurrenceState>(
      valueListenable: controller,
      builder: (context, occurrenceState, _) => Card(
        child: ListTile(
          title: Text(
            occurrenceState.data?.value ?? "",
            style: Theme.of(context).textTheme.subhead,
          ),
          trailing: _occurrenceMenuButton(context, controller),
        ),
      ),
    );
  }
}

Widget _occurrenceMenuButton(
    BuildContext context, NoteMapItemController controller) {
  return PopupMenuButton<_OccurrenceOption>(
    onSelected: (_OccurrenceOption choice) {
      switch (choice) {
        case _OccurrenceOption.delete:
          controller.delete().catchError((error) {
            Scaffold.of(context)
                .showSnackBar(SnackBar(content: Text(error.toString())));
            return null;
          });
          break;
      }
    },
    itemBuilder: (BuildContext context) => <PopupMenuEntry<_OccurrenceOption>>[
      const PopupMenuItem<_OccurrenceOption>(
        value: _OccurrenceOption.delete,
        child: Text('Delete'),
      ),
    ],
  );
}

enum _OccurrenceOption { delete }
