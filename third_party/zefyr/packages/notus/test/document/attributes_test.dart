// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:test/test.dart';
import 'package:notus/notus.dart';

/// Custom attribute that should work fine.
class CustomAttributeBuilder extends NotusAttributeBuilder<String> {
  const CustomAttributeBuilder() : super('custom', NotusAttributeScope.inline);
}

/// Custom attribute that is disallowed because it would replace a built-in attribute.
class DisallowedAttributeBuilder extends NotusAttributeBuilder<String> {
  const DisallowedAttributeBuilder() : super('b', NotusAttributeScope.line);
}

void main() {
  final customAttribute = CustomAttributeBuilder();
  group('$NotusAttribute', () {
    test('.register() works with a custom attribute', () {
      NotusAttribute.register(customAttribute);
    });
    test('.register() can be repeated without throwing an exception', () {
      NotusAttribute.register(customAttribute);
      NotusAttribute.register(customAttribute);
    });
    test('.register() rejects attributes that would override built-ins', () {
      expect(() => NotusAttribute.register(DisallowedAttributeBuilder()),
          throwsArgumentError);
    });
  });
  group('$NotusStyle', () {
    test('get', () {
      var attrs = NotusStyle.fromJson(<String, dynamic>{'block': 'ul'});
      var attr = attrs.get(NotusAttribute.block);
      expect(attr, NotusAttribute.ul);
    });
    test('.get() supports custom style attributes', () {
      NotusAttribute.register(customAttribute);
      var attrs = NotusStyle.fromJson(<String, dynamic>{'custom': 'test'});
      var attr = attrs.get(customAttribute);
      expect(attr, customAttribute.withValue('test'));
    });
    test('.put() supports custom style attributes', () {
      NotusAttribute.register(customAttribute);
      var attrs = NotusStyle.fromJson(<String, dynamic>{'custom': 'original'})
          .put(customAttribute.withValue('put'));
      var attr = attrs.get(customAttribute);
      expect(attr, customAttribute.withValue('put'));
    });
    test('.merge() supports custom style attributes', () {
      NotusAttribute.register(customAttribute);
      var attrs = NotusStyle.fromJson(<String, dynamic>{'custom': 'original'})
          .merge(customAttribute.withValue('merge'));
      var attr = attrs.get(customAttribute);
      expect(attr, customAttribute.withValue('merge'));
    });
    test('.removeAll() supports custom style attributes', () {
      NotusAttribute.register(customAttribute);
      var attrs = NotusStyle.fromJson(<String, dynamic>{'custom': 'original'})
          .removeAll([customAttribute]);
      expect(attrs.contains(customAttribute), false);
    });
  });
}
