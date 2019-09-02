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

class NameCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var controller = Provider.of<NameController>(context);
    return ValueListenableBuilder<NameState>(
      valueListenable: controller,
      builder: (context, nameState, _) => Card(
        child: ListTile(
          title: Text(
            nameState.data?.value ?? "",
            style: Theme.of(context).textTheme.headline,
          ),
          trailing: _nameMenuButton(context, controller),
        ),
      ),
    );
  }
}

Widget _nameMenuButton(BuildContext context, NoteMapItemController controller) {
  return PopupMenuButton<_NameOption>(
    onSelected: (_NameOption choice) {
      switch (choice) {
        case _NameOption.delete:
          controller.delete().catchError((error) {
            Scaffold.of(context)
                .showSnackBar(SnackBar(content: Text(error.toString())));
            return null;
          });
          break;
      }
    },
    itemBuilder: (BuildContext context) => <PopupMenuEntry<_NameOption>>[
      const PopupMenuItem<_NameOption>(
        value: _NameOption.delete,
        child: Text('Delete'),
      ),
    ],
  );
}

enum _NameOption { delete }
