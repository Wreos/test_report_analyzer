import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_report_analyzer/src/models/failure_analysis.dart';
import 'package:test_report_analyzer/src/models/test_failure.dart' as models;
import 'package:test_report_analyzer/src/output_generator.dart';

void main() {
  late Directory temporaryDirectory;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'test-report-analyzer-output-',
    );
  });

  tearDown(() async {
    await temporaryDirectory.delete(recursive: true);
  });

  test('escapes report data before writing HTML', () async {
    final outputPath = p.join(temporaryDirectory.path, 'report.html');
    final generator = OutputGenerator(
      outputFilePath: outputPath,
      reportSourcePath: '<source & "report">',
      summary: {
        'tests': '<4>',
        'failures': '1 & 2',
        'successRate': '75%',
        'duration': "1'00\"",
      },
      failures: [
        models.TestFailure(
          testName: '<script>alert("name")</script>',
          errorMessage: 'Expected <safe> & actual',
          stackTrace: "trace 'quoted'",
          testClass: 'Test',
          testMethod: 'renders',
        ),
      ],
      aiAnalyses: [
        FailureAnalysis(
          rootCause: '<b>unsafe</b>',
          suggestedFix: 'Use "escaped" output',
          additionalNotes: ['Do not trust <input>'],
        ),
      ],
    );

    await generator.generateReport();
    final html = await File(outputPath).readAsString();

    expect(html, contains('&lt;source &amp; &quot;report&quot;&gt;'));
    expect(html, contains('&lt;4&gt;'));
    expect(html, contains('1 &amp; 2'));
    expect(html, contains('1&#39;00&quot;'));
    expect(
      html,
      contains('&lt;script&gt;alert(&quot;name&quot;)&lt;/script&gt;'),
    );
    expect(html, contains('&lt;b&gt;unsafe&lt;/b&gt;'));
    expect(html, contains('Do not trust &lt;input&gt;'));
    expect(html, isNot(contains('<script>alert("name")</script>')));
  });

  test('renders a success card for a report with no failures', () async {
    final outputPath = p.join(temporaryDirectory.path, 'success.html');
    final generator = OutputGenerator(
      outputFilePath: outputPath,
      reportSourcePath: 'flutter test',
      summary: {
        'tests': '8',
        'failures': '0',
        'successRate': '100%',
        'duration': '2s',
      },
      failures: const [],
      aiAnalyses: const [],
    );

    await generator.generateReport();
    final html = await File(outputPath).readAsString();

    expect(html, contains('All Tests Passed'));
    expect(html, contains('100%'));
  });

  test('uses a manual fallback when an AI analysis is missing', () async {
    final outputPath = p.join(temporaryDirectory.path, 'fallback.html');
    final generator = OutputGenerator(
      outputFilePath: outputPath,
      reportSourcePath: 'flutter test',
      summary: {
        'tests': '1',
        'failures': '1',
        'successRate': '0%',
        'duration': '1s',
      },
      failures: [
        models.TestFailure(
          testName: 'ExampleTest.fails',
          errorMessage: 'Expected true but was false',
          stackTrace: 'example_test.dart:12',
          testClass: 'Test',
          testMethod: 'fails',
        ),
      ],
      aiAnalyses: const [],
    );

    await generator.generateReport();
    final html = await File(outputPath).readAsString();

    expect(html, contains('No AI analysis available'));
    expect(html, contains('Please check the test failure manually'));
  });
}
