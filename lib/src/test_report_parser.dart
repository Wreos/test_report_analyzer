import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';
import 'models/test_failure.dart';

/// Configuration for different test report formats
class TestReportFormat {
  final List<String> summarySelectors;
  final List<String> failureSelectors;
  final List<String> errorMessageSelectors;
  final List<String> stackTraceSelectors;
  final List<String> testNameSelectors;

  const TestReportFormat({
    required this.summarySelectors,
    required this.failureSelectors,
    required this.errorMessageSelectors,
    required this.stackTraceSelectors,
    required this.testNameSelectors,
  });

  /// Default format supporting multiple common patterns
  static const defaultFormat = TestReportFormat(
    summarySelectors: [
      '.summary-value',
      '#tests .counter',
      '.test-summary .count',
      '[data-test-count]',
      '.counter',
      '.infoBox .counter',
    ],
    failureSelectors: [
      '.failed',
      '.failure',
      '.test-failed',
      '#failures',
      '[data-test-status="failed"]',
      '.test-status.failed',
      '.test.failed',
      '.test-result.failed',
      '.test-case.failed',
      '.failure-container',
      '.test .test-status[class*="failed"]',
      '.test .test-status[class*="FAILED"]',
      '#tab0',
      '.tab',
    ],
    errorMessageSelectors: [
      '.test-message',
      '.error-message',
      '.failure-message',
      '.stacktrace',
      'pre',
      '.error-details',
      '.error-name',
      '.error-type',
      '.test-error',
      '.code',
      '.error-message',
    ],
    stackTraceSelectors: [
      '.stacktrace',
      'pre',
      '.stack-trace',
      '.error-stack',
      '.error-details pre',
      '.test-error pre',
      '.code pre',
    ],
    testNameSelectors: [
      '.test-name',
      '.test-case',
      '.test-title',
      'h3',
      '.test-header',
      '.test-class',
      '.test h3',
      'h2',
    ],
  );
}

class TestReportParser {
  final TestReportFormat format;

  TestReportParser({this.format = TestReportFormat.defaultFormat});

  List<TestFailure> parseReport(String htmlContent) {
    final document = parser.parse(htmlContent);
    final failures = <TestFailure>[];

    try {
      _parseSummary(document);
      failures.addAll(_parseFailures(document));
    } catch (e) {
      print('Warning: Error parsing test report: $e');
      // Try alternative parsing strategies if primary fails
      failures.addAll(_fallbackParsing(document));
    }

    return failures;
  }

  void _parseSummary(Document document) {
    // Try different summary formats
    int? testCount;
    int? failureCount;
    String? duration;
    String? successRate;

    // Try to find test count
    for (final selector in format.summarySelectors) {
      final element = document.querySelector(selector);
      if (element != null) {
        final text = element.text.replaceAll(RegExp(r'[^\d.]'), '');
        testCount = int.tryParse(text);
        if (testCount != null) break;
      }
    }

    // Try to find failure count
    for (final selector in format.failureSelectors) {
      final element = document.querySelector(selector);
      if (element != null) {
        final text = element.text.replaceAll(RegExp(r'[^\d.]'), '');
        failureCount = int.tryParse(text);
        if (failureCount != null) break;
      }
    }

    print('Test Summary:');
    print('Total Tests: ${testCount ?? "unknown"}');
    print('Failures: ${failureCount ?? "unknown"}');
    print('Duration: ${duration ?? "unknown"}');
    print('Success Rate: ${successRate ?? "unknown"}');
  }

  List<TestFailure> _parseFailures(Document document) {
    final failures = <TestFailure>[];

    // Find all potential failure containers
    for (final failureSelector in format.failureSelectors) {
      final failureElements = document.querySelectorAll(failureSelector);

      for (final element in failureElements) {
        final failure = _extractFailureInfo(element);
        if (failure != null) {
          failures.add(failure);
        }
      }
    }

    return failures;
  }

  TestFailure? _extractFailureInfo(Element element) {
    String? testName;
    String? errorMessage;
    String? stackTrace;

    // Try to find test name
    for (final selector in format.testNameSelectors) {
      final nameElement = element.querySelector(selector) ?? element;
      testName = nameElement.text.trim();
      if (testName.isNotEmpty) break;
    }

    // Try to find error message
    for (final selector in format.errorMessageSelectors) {
      final messageElement = element.querySelector(selector);
      if (messageElement != null) {
        errorMessage = messageElement.text.trim();
        if (errorMessage.isNotEmpty) break;
      }
    }

    // Try to find stack trace
    for (final selector in format.stackTraceSelectors) {
      final traceElement = element.querySelector(selector);
      if (traceElement != null) {
        stackTrace = traceElement.text.trim();
        if (stackTrace.isNotEmpty) break;
      }
    }

    if (testName != null || errorMessage != null) {
      return TestFailure(
        testName: testName ?? 'Unknown Test',
        errorMessage: errorMessage ?? '',
        stackTrace: stackTrace ?? '',
        testClass: _determineTestClass(element),
        testMethod: _determineTestMethod(testName ?? ''),
      );
    }

    return null;
  }

  String _determineTestClass(Element element) {
    // Try to determine if this is a tool failure or test failure
    final isToolFailure = element.parent?.id == 'tab0' ||
        element.text.toLowerCase().contains('install') ||
        element.text.toLowerCase().contains('setup') ||
        element.text.toLowerCase().contains('device');
    return isToolFailure ? 'Tool' : 'Test';
  }

  String _determineTestMethod(String testName) {
    // Try to extract method name from test name
    if (testName.contains('.')) {
      return testName.split('.').last;
    } else if (testName.contains('test')) {
      return testName.toLowerCase().contains('setup') ? 'setup' : 'execution';
    }
    return 'execution';
  }

  List<TestFailure> _fallbackParsing(Document document) {
    final failures = <TestFailure>[];

    // Last resort: look for any error-like content
    final errorIndicators = [
      'error',
      'failure',
      'failed',
      'exception',
      'stacktrace',
    ];

    // Search through all elements for error indicators
    document.body?.querySelectorAll('*').forEach((element) {
      final text = element.text.toLowerCase();
      if (errorIndicators.any((indicator) => text.contains(indicator))) {
        final failure = TestFailure(
          testName: 'Unknown Test',
          errorMessage: element.text.trim(),
          stackTrace: '',
          testClass: text.contains('setup') ? 'Tool' : 'Test',
          testMethod: 'unknown',
        );
        failures.add(failure);
      }
    });

    return failures;
  }
}
