import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  final packageRoot = Directory.current.path;

  Map<String, String> cleanEnvironment({String? openAiKey}) {
    final environment = Map<String, String>.from(Platform.environment)
      ..remove('OPENAI_API_KEY')
      ..remove('ANTHROPIC_API_KEY');
    if (openAiKey != null) {
      environment['OPENAI_API_KEY'] = openAiKey;
    }
    return environment;
  }

  Future<ProcessResult> runCli(
    List<String> arguments, {
    Map<String, String>? environment,
  }) {
    return Process.run(
      Platform.resolvedExecutable,
      ['run', 'test_report_analyzer', ...arguments],
      workingDirectory: packageRoot,
      environment: environment ?? cleanEnvironment(),
      includeParentEnvironment: false,
    );
  }

  group('command line interface', () {
    test('--help prints usage and exits successfully', () async {
      final result = await runCli(['--help']);

      expect(result.exitCode, 0);
      expect(result.stdout, contains('Usage: dart run test_report_analyzer'));
      expect(result.stdout, contains('--reports-path'));
      expect(result.stdout, contains('--anthropic-key'));
    });

    test('--version prints the package version', () async {
      final result = await runCli(['--version']);

      expect(result.exitCode, 0);
      expect(result.stdout, contains('test_report_analyzer version 1.0.0'));
    });

    test('unknown arguments return a non-zero exit code', () async {
      final result = await runCli(['--unknown-option']);

      expect(result.exitCode, 1);
      expect(result.stdout, contains('Could not find an option named'));
      expect(result.stdout, contains('Usage:'));
    });

    test('missing API credentials return a non-zero exit code', () async {
      final result = await runCli([]);

      expect(result.exitCode, 1);
      expect(
        result.stdout,
        contains('Either OpenAI API key or Anthropic API key'),
      );
    });

    test('accepts an API key from the environment', () async {
      final temporaryDirectory = await Directory.systemTemp.createTemp(
        'test-report-analyzer-cli-',
      );
      addTearDown(() => temporaryDirectory.delete(recursive: true));
      final reportDirectory = Directory(
        p.join(temporaryDirectory.path, 'reports', 'qa'),
      );
      await reportDirectory.create(recursive: true);
      await File(
        p.join(reportDirectory.path, 'report.html'),
      ).writeAsString('<html><body>All tests passed.</body></html>');
      final relativeReportsPath = p.relative(
        p.join(temporaryDirectory.path, 'reports'),
        from: packageRoot,
      );

      final result = await runCli([
        '--reports-path',
        relativeReportsPath,
        '--flavor',
        'qa',
      ], environment: cleanEnvironment(openAiKey: 'environment-key'));

      expect(result.exitCode, 0);
      expect(result.stdout, contains('No test failures found.'));
    });

    test('missing report directories return a non-zero exit code', () async {
      final result = await runCli([
        '--reports-path',
        'definitely-missing-test-reports',
        '--flavor',
        'qa',
      ], environment: cleanEnvironment(openAiKey: 'environment-key'));

      expect(result.exitCode, 1);
      expect(result.stdout, contains('Flavor directory not found'));
      expect(result.stdout, contains('Could not find test file'));
    });
  });
}
