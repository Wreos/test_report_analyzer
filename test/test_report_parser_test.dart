import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_report_analyzer/src/test_report_parser.dart';

void main() {
  final parser = TestReportParser();

  String fixture(String name) {
    return File(p.join('test', 'fixtures', name)).readAsStringSync();
  }

  group('TestReportParser', () {
    test('parses Android failures without selector duplicates', () {
      final failures = parser.parseReport(fixture('android_report.html'));

      expect(failures, hasLength(2));
      expect(
        failures.map((failure) => failure.testName),
        containsAll([
          'com.example.LoginTest.invalidCredentials',
          'com.example.PaymentTest.timesOut',
        ]),
      );
      expect(failures.first.testClass, 'Test');
      expect(failures.first.testMethod, 'invalidCredentials');
      expect(failures.first.errorMessage, contains('network error'));
      expect(failures.first.stackTrace, contains('LoginTest.kt:42'));
    });

    test('parses Flutter HTML failures', () {
      final failures = parser.parseReport(fixture('flutter_report.html'));

      expect(failures, hasLength(1));
      expect(failures.single.testName, 'CheckoutPage.rendersErrorState');
      expect(failures.single.testMethod, 'rendersErrorState');
      expect(failures.single.errorMessage, contains('error banner'));
      expect(failures.single.stackTrace, contains('widget_tester.dart'));
    });

    test('prints total and failure counts from the report summary', () {
      final messages = <String>[];

      runZoned(
        () => parser.parseReport(fixture('android_report.html')),
        zoneSpecification: ZoneSpecification(
          print: (_, _, _, message) => messages.add(message),
        ),
      );

      expect(messages, contains('Total Tests: 4'));
      expect(messages, contains('Failures: 2'));
    });

    test('handles malformed HTML without throwing', () {
      const malformed = '''
        <html><body><div class="failed">
          <span class="test-name">BrokenTest.crashes
          <pre>StateError: broken
      ''';

      final failures = parser.parseReport(malformed);

      expect(failures, hasLength(1));
      expect(failures.single.testName, contains('BrokenTest.crashes'));
      expect(failures.single.errorMessage, contains('StateError'));
    });

    test('returns no failures for an empty report', () {
      final failures = parser.parseReport(
        '<html><body><p>All tests passed.</p></body></html>',
      );

      expect(failures, isEmpty);
    });

    test('classifies setup and device errors as tool failures', () {
      const report = '''
        <html><body>
          <div class="failed">
            <span class="test-name">Device setup failed</span>
            <span class="error-message">Unable to install APK</span>
          </div>
        </body></html>
      ''';

      final failures = parser.parseReport(report);

      expect(failures, hasLength(1));
      expect(failures.single.testClass, 'Tool');
      expect(failures.single.testMethod, 'setup');
    });
  });
}
