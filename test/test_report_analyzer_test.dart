import 'package:test/test.dart';
import 'package:test_report_analyzer/test_report_analyzer.dart';

void main() {
  test('TestReportAnalyzer initialization', () {
    final analyzer = TestReportAnalyzer(apiKey: 'test-key');
    expect(analyzer, isNotNull);
  });
}
