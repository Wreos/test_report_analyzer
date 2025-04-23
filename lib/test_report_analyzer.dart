/// A powerful tool for analyzing Android and Flutter test reports using AI
/// to provide insights, root cause analysis, and suggested fixes for test failures.
library test_report_analyzer;

import 'dart:io';
import 'package:html/parser.dart' as html_parser;
import 'package:path/path.dart' as p;
import 'src/models/test_failure.dart';
import 'src/models/failure_analysis.dart';
import 'src/ai_service.dart';
import 'src/output_generator.dart';
import 'src/test_report_parser.dart';

/// A class for analyzing test reports using AI
class TestReportAnalyzer {
  final String apiKey;
  final bool useAnthropicInstead;

  /// Creates a new [TestReportAnalyzer] instance.
  ///
  /// [apiKey] is the API key for either OpenAI or Anthropic.
  /// [useAnthropicInstead] determines which AI service to use (defaults to OpenAI).
  TestReportAnalyzer({
    required this.apiKey,
    this.useAnthropicInstead = false,
  });

  /// Analyzes test reports in the specified directory
  Future<AnalysisResults> analyzeReports({
    required String reportsPath,
    required String flavor,
  }) async {
    final testFilePath = await _findTestFile(reportsPath, flavor);
    if (testFilePath == null) {
      throw Exception('Could not find test file in the specified directory');
    }

    final failedTestFiles = await _getFailedTestFiles(testFilePath);
    if (failedTestFiles.isEmpty) {
      return AnalysisResults(failures: []);
    }

    final reportParser = TestReportParser();
    final List<TestFailure> allFailures = [];

    for (final testFile in failedTestFiles) {
      final file = File(testFile);
      if (!await file.exists()) {
        print('Warning: Test file not found: $testFile');
        continue;
      }

      final content = await file.readAsString();
      final failures = reportParser.parseReport(content);
      allFailures.addAll(failures);
    }

    if (allFailures.isEmpty) {
      return AnalysisResults(failures: []);
    }

    final aiService = useAnthropicInstead
        ? AnthropicService(
            apiKey: apiKey,
            model: 'claude-3-opus-20240229',
            apiUrl: 'https://api.anthropic.com/v1/messages',
          )
        : OpenAiService(
            apiKey: apiKey,
            model: 'gpt-3.5-turbo',
            apiUrl: 'https://api.openai.com/v1/chat/completions',
          );

    final List<FailureAnalysis> analyses = [];
    for (final failure in allFailures) {
      try {
        final analysis = await aiService.analyzeFailure(failure);
        failure.analysis = analysis;
        analyses.add(analysis);
      } catch (e) {
        print('Error analyzing failure: $e');
      }
    }

    return AnalysisResults(
      failures: allFailures,
      analyses: analyses,
    );
  }

  /// Generates an HTML report from the analysis results.
  ///
  /// [results] contains the test failures and their analyses.
  /// [outputPath] is where to save the generated HTML report.
  Future<void> generateReport({
    required AnalysisResults results,
    required String outputPath,
  }) async {
    final outputGenerator = OutputGenerator(
      outputFilePath: outputPath,
      reportSourcePath: results.failures.first.testClass,
      summary: {
        'tests': '${results.failures.length}',
        'failures': '${results.failures.length}',
        'successRate': '0%',
        'duration': 'N/A'
      },
      failures: results.failures,
      aiAnalyses: results.analyses,
    );

    await outputGenerator.generateReport();
  }

  /// Finds the test report file in the specified directory.
  ///
  /// [reportsPath] is the base directory containing test reports.
  /// [flavor] is the build flavor (e.g., qa, dev, prod).
  ///
  /// Returns the path to the test report file, or null if not found.
  Future<String?> _findTestFile(String reportsPath, String flavor) async {
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

    final allFiles = await _listDirectoryContents(flavorDirPath);
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

  /// Lists all contents of a directory recursively.
  ///
  /// [path] is the directory to list contents of.
  ///
  /// Returns a list of all files and directories in the given path.
  Future<List<FileSystemEntity>> _listDirectoryContents(String path) async {
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

  /// Gets a list of test files that contain failures.
  ///
  /// [testFilePath] is the path to the main test report file.
  ///
  /// Returns a list of paths to test files that contain failures.
  Future<List<String>> _getFailedTestFiles(String testFilePath) async {
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
}

/// Results of analyzing test reports
class AnalysisResults {
  final List<TestFailure> failures;
  final List<FailureAnalysis> analyses;

  AnalysisResults({
    required this.failures,
    List<FailureAnalysis>? analyses,
  }) : analyses = analyses ?? [];
}
