import 'failure_analysis.dart';

class TestFailure {
  final String testName;
  final String errorMessage;
  final String stackTrace;
  final String testClass;
  final String testMethod;
  FailureAnalysis? analysis;

  TestFailure({
    required this.testName,
    required this.errorMessage,
    required this.stackTrace,
    required this.testClass,
    required this.testMethod,
    this.analysis,
  });

  @override
  String toString() {
    return '''
Test Failure:
  Class: $testClass
  Method: $testMethod
  Name: $testName
  Error: $errorMessage
  Stack Trace:
$stackTrace
''';
  }
}
