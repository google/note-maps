import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nm_gql_go_link/nm_gql_go_link.dart';

void main() {
  const MethodChannel channel = MethodChannel('nm_gql_go_link');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await NmGqlGoLink.platformVersion, '42');
  });
}
