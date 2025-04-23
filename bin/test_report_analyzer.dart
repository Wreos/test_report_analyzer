#!/usr/bin/env dart

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:args/args.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:test_report_analyzer/test_report_analyzer.dart';

// --- Helper Functions ---
Future<List<FileSystemEntity>> listDirectoryContents(String path) async {
  try {
    final dir = Directory(path);
    if (!await dir.exists()) {
      print('Warning: Directory does not exist: $path');
      return [];
    }
    return await dir.list(recursive: true).toList();
  } catch (e) {
    print('Warning: Error listing directory contents: $e');
    return [];
  }
}

Future<String?> findTestFile(String reportsPath, String flavor) async {
  final currentDir = Directory.current.path;
  final mainAppReportsPath = p.join(currentDir, reportsPath);
  final flavorDirPath = p.join(mainAppReportsPath, flavor);

  print('Searching for test reports in: $flavorDirPath');

  final flavorDir = Directory(flavorDirPath);
  if (!await flavorDir.exists()) {
    print('Error: Flavor directory not found: $flavorDirPath');
    print('Current working directory: $currentDir');
    print('Available directories in ${p.dirname(flavorDirPath)}:');
    try {
      final parentDir = Directory(p.dirname(flavorDirPath));
      if (await parentDir.exists()) {
        final contents = await parentDir.list().toList();
        for (final entity in contents) {
          if (entity is Directory) {
            print('- ${p.basename(entity.path)}');
          }
        }
      }
    } catch (e) {
      print('Could not list directory contents: $e');
    }
    print('Did you run the tests (e.g., ./gradlew connectedCheck)?');
    return null;
  }

  final allFiles = await listDirectoryContents(flavorDirPath);
  final htmlFiles = allFiles
      .whereType<File>()
      .where((f) => p.extension(f.path) == '.html')
      .toList();

  if (htmlFiles.isEmpty) {
    print('Error: No HTML files found in: $flavorDirPath');
    return null;
  }

  return htmlFiles.first.path;
}

Future<List<String>> getFailedTestFiles(String testFilePath) async {
  final testFile = File(testFilePath);
  final content = await testFile.readAsString();
  final document = html_parser.parse(content);

  final toolFailures = document.querySelector('#tab0');
  if (toolFailures != null && toolFailures.text.isNotEmpty) {
    return [testFilePath];
  }

  final hasFailures =
      document.body?.text.toLowerCase().contains('failed') == true ||
          document.querySelector('.failed') != null ||
          document.querySelector('.error') != null;

  if (hasFailures) {
    return [testFilePath];
  }

  return [];
}

// --- Main Execution Logic ---
void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('reports-path',
        help: 'Path to the test reports directory',
        defaultsTo: 'build/app/reports/androidTests/connected/debug/flavors')
    ..addOption('flavor',
        help: 'Build flavor to analyze (e.g., qa, dev, prod)', defaultsTo: 'qa')
    ..addOption('openai-key',
        help: 'OpenAI API key (optional if anthropic-key is provided)')
    ..addOption('anthropic-key',
        help: 'Anthropic API key (optional if openai-key is provided)')
    ..addOption('output',
        help: 'Path to save the analysis report',
        defaultsTo: 'ai_analysis_report.html')
    ..addFlag('help',
        abbr: 'h', help: 'Show this help message', negatable: false)
    ..addFlag('version', help: 'Show version', negatable: false);

  ArgResults args;
  try {
    args = parser.parse(arguments);
  } catch (e) {
    print('Error: $e\n');
    printUsage(parser);
    exit(1);
  }

  if (args['help']) {
    printUsage(parser);
    exit(0);
  }

  if (args['version']) {
    print('test_report_analyzer version 1.0.0');
    exit(0);
  }

  final openAiKey =
      args['openai-key'] ?? Platform.environment['OPENAI_API_KEY'];
  final anthropicKey =
      args['anthropic-key'] ?? Platform.environment['ANTHROPIC_API_KEY'];

  if (openAiKey == null && anthropicKey == null) {
    print('Error: Either OpenAI API key or Anthropic API key must be provided');
    print('You can provide them via:');
    print('1. Command line arguments: --openai-key or --anthropic-key');
    print('2. Environment variables: OPENAI_API_KEY or ANTHROPIC_API_KEY');
    exit(1);
  }

  final reportsPath = args['reports-path'];
  final flavor = args['flavor'];
  final outputPath = args['output'];

  try {
    final analyzer = TestReportAnalyzer(
      apiKey: openAiKey ?? anthropicKey!,
      useAnthropicInstead: openAiKey == null,
    );

    print('Analyzing test reports...');
    final results = await analyzer.analyzeReports(
      reportsPath: reportsPath,
      flavor: flavor,
    );

    if (results.failures.isEmpty) {
      print('No test failures found.');
      exit(0);
    }

    print('Generating report...');
    await analyzer.generateReport(
      results: results,
      outputPath: outputPath,
    );

    print('\nAnalysis complete! Report saved to: $outputPath');

    // Print summary to console
    print('\nSummary of findings:');
    print('Total failures analyzed: ${results.failures.length}');
    for (final failure in results.failures) {
      print('\nTest: ${failure.testName}');
      print(
          'Root cause: ${failure.analysis?.rootCause ?? 'No root cause analysis available'}');
      print(
          'Suggested fix: ${failure.analysis?.suggestedFix ?? 'No suggested fix available'}');
    }
  } catch (e, stackTrace) {
    print('Error analyzing test reports: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}

void printUsage(ArgParser parser) {
  print('Usage: dart run test_report_analyzer [options]\n');
  print('Options:');
  print(parser.usage);
  print('\nExample:');
  print(
      '  dart run test_report_analyzer --reports-path path/to/reports --flavor qa --openai-key YOUR_API_KEY');
}
