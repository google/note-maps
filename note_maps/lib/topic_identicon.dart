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
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jdenticon_dart/jdenticon_dart.dart';

class TopicIdenticon extends StatelessWidget {
  final dynamic item;
  final BoxFit fit;
  final Alignment alignment;
  final double size;
  final Color backgroundColor;

  TopicIdenticon(
    this.item, {
    Key key,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.backgroundColor = Colors.white,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (item == null || item.id == null) {
      return Container(alignment: alignment);
    }
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color:Colors.black,width:1.0),
      ),
      child: ClipOval(
        child: Stack(children: <Widget>[
          Container(
            color: Colors.white,
            width: size,
            height: size,
          ),
          SvgPicture.string(
            Jdenticon.toSvg((item?.id ?? 0).toRadixString(16)),
            fit: fit,
            alignment: alignment,
            width: size,
            height: size,
          ),
        ]),
      ),
    );
  }
}
