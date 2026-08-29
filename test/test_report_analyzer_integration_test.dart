import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_report_analyzer/test_report_analyzer.dart';

void main() {
  late Directory temporaryDirectory;
  late TestReportAnalyzer analyzer;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'test-report-analyzer-integration-',
    );
    analyzer = TestReportAnalyzer(apiKey: 'unused-test-key');
  });

  tearDown(() async {
    await temporaryDirectory.delete(recursive: true);
  });

  String relativePath(String path) {
    return p.relative(path, from: Directory.current.path);
  }

  test(
    'returns empty results when the discovered report has no failures',
    () async {
      final reportsDirectory = Directory(
        p.join(temporaryDirectory.path, 'reports', 'qa'),
      );
      await reportsDirectory.create(recursive: true);
      await File(
        p.join(reportsDirectory.path, 'report.html'),
      ).writeAsString('<html><body><p>All tests passed.</p></body></html>');

      final results = await analyzer.analyzeReports(
        reportsPath: relativePath(p.join(temporaryDirectory.path, 'reports')),
        flavor: 'qa',
      );

      expect(results.failures, isEmpty);
      expect(results.analyses, isEmpty);
    },
  );

  test('throws a useful error when the flavor directory is missing', () async {
    final reportsPath = p.join(temporaryDirectory.path, 'reports');
    await Directory(reportsPath).create();

    expect(
      () => analyzer.analyzeReports(
        reportsPath: relativePath(reportsPath),
        flavor: 'qa',
      ),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('Could not find test file'),
        ),
      ),
    );
  });

  test(
    'throws a useful error when the flavor directory has no HTML files',
    () async {
      final reportsDirectory = Directory(
        p.join(temporaryDirectory.path, 'reports', 'qa'),
      );
      await reportsDirectory.create(recursive: true);
      await File(
        p.join(reportsDirectory.path, 'results.txt'),
      ).writeAsString('No HTML report was generated.');

      expect(
        () => analyzer.analyzeReports(
          reportsPath: relativePath(p.join(temporaryDirectory.path, 'reports')),
          flavor: 'qa',
        ),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Could not find test file'),
          ),
        ),
      );
    },
  );
}
