import 'dart:io';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import 'package:path/path.dart' as path;
import 'models/test_failure.dart';

class ReportParser {
  final String reportPath;

  ReportParser(this.reportPath);

  Future<List<TestFailure>> parse() async {
    final file = File(reportPath);
    if (!await file.exists()) {
      throw Exception('Report file not found: $reportPath');
    }

    final content = await file.readAsString();
    final document = html_parser.parse(content);
    final failures = <TestFailure>[];

    failures.addAll(_extractToolFailures(document));
    failures.addAll(_extractGradleSummary(document));
    failures.addAll(_extractSummary(document));
    failures.addAll(_extractFailures(document));

    return failures;
  }

  List<TestFailure> _extractToolFailures(Document document) {
    final failures = <TestFailure>[];
    final toolFailureElements = document.querySelectorAll('.tool-failure');

    for (final element in toolFailureElements) {
      final name = element.querySelector('.failure-name')?.text ?? 'Unknown Tool Failure';
      final details = element.querySelector('.failure-details')?.text ?? 'No details available';

      failures.add(
        TestFailure(
          testName: name,
          errorMessage: details,
          stackTrace: '',
          testClass: 'ToolFailure',
          testMethod: 'toolExecution',
        ),
      );
    }

    return failures;
  }

  List<TestFailure> _extractGradleSummary(Document document) {
    final failures = <TestFailure>[];
    final gradleFailureElements = document.querySelectorAll('.gradle-failure');

    for (final element in gradleFailureElements) {
      final name = element.querySelector('.failure-name')?.text ?? 'Unknown Gradle Failure';
      final details = element.querySelector('.failure-details')?.text ?? 'No details available';

      failures.add(
        TestFailure(
          testName: name,
          errorMessage: details,
          stackTrace: '',
          testClass: 'GradleFailure',
          testMethod: 'gradleExecution',
        ),
      );
    }

    return failures;
  }

  List<TestFailure> _extractSummary(Document document) {
    final failures = <TestFailure>[];
    final summaryElement = document.querySelector('.summary, #summary');

    if (summaryElement != null) {
      final summaryText = summaryElement.text;
      if (summaryText.contains('FAILED') || summaryText.contains('Error')) {
        failures.add(
          TestFailure(
            testName: 'Test Summary',
            errorMessage: summaryText,
            stackTrace: '',
            testClass: 'Summary',
            testMethod: 'summary',
          ),
        );
      }
    }

    return failures;
  }

  List<TestFailure> _extractFailures(Document document) {
    final failures = <TestFailure>[];
    final failureElements = document.querySelectorAll('.test-failure');

    for (final element in failureElements) {
      final testClass = element.querySelector('.test-class')?.text ?? 'Unknown Class';
      final testMethod = element.querySelector('.test-method')?.text ?? 'Unknown Method';
      final name = element.querySelector('.failure-name')?.text ?? 'Unknown Test Failure';
      final details = element.querySelector('.failure-details')?.text ?? 'No details available';
      final stackTrace = element.querySelector('.stack-trace')?.text ?? '';

      failures.add(
        TestFailure(
          testName: name,
          errorMessage: details,
          stackTrace: stackTrace,
          testClass: testClass,
          testMethod: testMethod,
        ),
      );
    }

    return failures;
  }

  Future<List<TestFailure>> parseFailures() async {
    final file = File(reportPath);
    if (!await file.exists()) {
      throw Exception('Report file not found: $reportPath');
    }

    final content = await file.readAsString();
    final document = html_parser.parse(content);

    // Extract test class name from file name
    final fileName = path.basename(reportPath);
    final testClass = fileName.replaceAll('.html', '');

    final failures = <TestFailure>[];
    final failureElements = document.querySelectorAll('.test-result.failed');

    for (final element in failureElements) {
      final testName = element.querySelector('.test-name')?.text ?? 'Unknown Test';
      final errorText = element.querySelector('.stacktrace')?.text ?? '';

      // Split error text into message and stack trace
      final parts = errorText.split('\n');
      final errorMessage = parts.first;
      final stackTrace = parts.skip(1).join('\n');

      // Extract test method name from test name
      final testMethod = testName.split(' ').first;

      failures.add(
        TestFailure(
          testName: testName,
          errorMessage: errorMessage,
          stackTrace: stackTrace,
          testClass: testClass,
          testMethod: testMethod,
        ),
      );
    }

    return failures;
  }
}
