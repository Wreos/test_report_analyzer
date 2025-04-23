import 'dart:io';
// import 'package:test_report_analyzer/src/report_parser.dart'; // Ensure TestFailure is imported
import 'models/test_failure.dart';
import 'models/failure_analysis.dart';

/// A class responsible for generating HTML reports from test analysis results.
///
/// This class takes test failures and their AI analyses and generates a detailed
/// HTML report with styling, summary cards, and failure details.
class OutputGenerator {
  /// The path where the output HTML report will be saved
  final String outputFilePath;

  /// The path to the source test report that was analyzed
  final String reportSourcePath;

  /// A map containing summary statistics about the test run
  final Map<String, String> summary;

  /// List of test failures that were found during analysis
  final List<TestFailure> failures;

  /// List of AI analyses corresponding to each test failure
  final List<FailureAnalysis> aiAnalyses;

  /// Creates a new [OutputGenerator] instance.
  ///
  /// [outputFilePath] is where the HTML report will be saved.
  /// [reportSourcePath] is the path to the original test report.
  /// [summary] contains statistics about the test run.
  /// [failures] is a list of test failures to include in the report.
  /// [aiAnalyses] contains AI-generated analyses for each failure.
  OutputGenerator({
    required this.outputFilePath,
    required this.reportSourcePath,
    required this.summary,
    required this.failures,
    required this.aiAnalyses,
  });

  /// Generates an HTML report from the test analysis results.
  ///
  /// The report includes:
  /// - A header with source information
  /// - Summary cards showing test statistics
  /// - Detailed failure information with AI analysis
  /// - Error details and stack traces
  Future<void> generateReport() async {
    final buffer = StringBuffer();

    // Start HTML Document
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html lang="en">');
    buffer.writeln('<head>');
    buffer.writeln('  <meta charset="UTF-8">');
    buffer.writeln(
        '  <meta name="viewport" content="width=device-width, initial-scale=1.0">');
    buffer.writeln('  <title>Test Analysis Report</title>');
    buffer.writeln('  <style>');
    _writeStyles(buffer);
    buffer.writeln('  </style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');

    _writeHeader(buffer);
    _writeSummaryCards(buffer);
    _writeFailures(buffer);

    buffer.writeln('</body>');
    buffer.writeln('</html>');

    final outputFile = File(outputFilePath);
    await outputFile.writeAsString(buffer.toString());
    print('Analysis report generated: $outputFilePath');
  }

  /// Writes the CSS styles for the HTML report.
  ///
  /// This method defines the visual styling for all report components,
  /// including colors, layout, and responsive design.
  void _writeStyles(StringBuffer buffer) {
    buffer.writeln('''
      :root {
        --primary: #0553B1;
        --error: #DC2626;
        --tool-error: #7C3AED;
        --success: #059669;
        --warning: #D97706;
        --bg-light: #F3F4F6;
        --text-primary: #1F2937;
        --text-secondary: #4B5563;
      }
      
      body {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        line-height: 1.6;
        margin: 0;
        padding: 0;
        background: var(--bg-light);
        color: var(--text-primary);
      }

      .container {
        max-width: 1200px;
        margin: 0 auto;
        padding: 2rem;
      }

      .header {
        background: white;
        padding: 2rem;
        box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        margin-bottom: 2rem;
      }

      .header h1 {
        color: var(--primary);
        margin: 0;
        font-size: 2rem;
      }

      .header p {
        color: var(--text-secondary);
        margin: 0.5rem 0 0;
      }

      .summary-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
        gap: 1rem;
        margin-bottom: 2rem;
      }

      .summary-card {
        background: white;
        padding: 1.5rem;
        border-radius: 8px;
        box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        text-align: center;
      }

      .summary-card h3 {
        margin: 0;
        color: var(--text-secondary);
        font-size: 0.875rem;
        text-transform: uppercase;
        letter-spacing: 0.05em;
      }

      .summary-card .value {
        font-size: 2rem;
        font-weight: bold;
        margin: 0.5rem 0;
      }

      .failure-card {
        background: white;
        margin: 1rem 0;
        padding: 1.5rem;
        border-radius: 8px;
        box-shadow: 0 1px 3px rgba(0,0,0,0.1);
      }

      .failure-header {
        display: flex;
        align-items: center;
        margin-bottom: 1rem;
      }

      .failure-badge {
        padding: 0.25rem 0.75rem;
        border-radius: 4px;
        font-size: 0.875rem;
        margin-right: 1rem;
        font-weight: 500;
      }

      .failure-badge.test {
        background: #FEE2E2;
        color: var(--error);
      }

      .failure-badge.tool {
        background: #EDE9FE;
        color: var(--tool-error);
      }

      .failure-name {
        font-size: 1.25rem;
        font-weight: 600;
        color: var(--text-primary);
      }

      .analysis-section {
        background: #F8FAFC;
        padding: 1rem;
        border-radius: 6px;
        margin: 1rem 0;
      }

      .analysis-section h4 {
        color: var(--primary);
        margin: 0 0 0.5rem;
        display: flex;
        align-items: center;
        gap: 0.5rem;
      }

      .analysis-section h4::before {
        content: "🔍";
      }

      .code-section {
        background: #1F2937;
        color: #E5E7EB;
        padding: 1rem;
        border-radius: 6px;
        overflow-x: auto;
        font-family: 'Fira Code', 'Consolas', monospace;
      }

      .code-section pre {
        margin: 0;
      }

      .recommendations {
        background: #ECFDF5;
        padding: 1rem;
        border-radius: 6px;
        margin: 1rem 0;
      }

      .recommendations h4::before {
        content: "💡";
      }

      .recommendations ul {
        margin: 0;
        padding-left: 1.5rem;
      }

      .recommendations li {
        margin: 0.5rem 0;
      }

      .error-details {
        margin-top: 1rem;
      }

      .error-details summary {
        cursor: pointer;
        padding: 0.5rem;
        background: #F1F5F9;
        border-radius: 4px;
        font-weight: 500;
      }

      .error-details pre {
        background: #F8FAFC;
        padding: 1rem;
        border-radius: 4px;
        overflow-x: auto;
        margin: 0.5rem 0;
      }

      .tool-error {
        background: #F5F3FF;
        border-left: 4px solid var(--tool-error);
      }

      .tool-error .error-details pre {
        background: #EDE9FE;
      }

      .tool-error .recommendations {
        background: #F5F3FF;
      }

      .tool-error .analysis-section {
        background: #F5F3FF;
      }

      .failure-type-tabs {
        display: flex;
        gap: 1rem;
        margin-bottom: 1rem;
      }

      .failure-type-tab {
        padding: 0.5rem 1rem;
        border-radius: 4px;
        cursor: pointer;
        font-weight: 500;
        background: #F1F5F9;
      }

      .failure-type-tab.active {
        background: var(--primary);
        color: white;
      }
    ''');
  }

  /// Writes the header section of the HTML report.
  ///
  /// The header includes:
  /// - Report title
  /// - Source file path
  /// - Generation timestamp
  void _writeHeader(StringBuffer buffer) {
    buffer.writeln('''
      <div class="header">
        <div class="container">
          <h1>Test Analysis Report</h1>
          <p>Source: <code>${_escapeHtml(reportSourcePath)}</code></p>
          <p>Generated: ${DateTime.now()}</p>
        </div>
      </div>
    ''');
  }

  /// Writes the summary cards section of the HTML report.
  ///
  /// Creates a grid of cards showing:
  /// - Total number of tests
  /// - Number of failures
  /// - Success rate
  /// - Test duration
  void _writeSummaryCards(StringBuffer buffer) {
    buffer.writeln('<div class="container">');
    buffer.writeln('  <div class="summary-grid">');

    final summaryItems = [
      {
        'label': 'Total Tests',
        'value': summary['tests'],
        'color': 'var(--primary)'
      },
      {
        'label': 'Failures',
        'value': summary['failures'],
        'color': 'var(--error)'
      },
      {
        'label': 'Success Rate',
        'value': summary['successRate'],
        'color': 'var(--success)'
      },
      {
        'label': 'Duration',
        'value': summary['duration'],
        'color': 'var(--text-primary)'
      },
    ];

    for (final item in summaryItems) {
      buffer.writeln('''
        <div class="summary-card">
          <h3>${item['label']}</h3>
          <div class="value" style="color: ${item['color']}">${item['value'] ?? 'N/A'}</div>
        </div>
      ''');
    }

    buffer.writeln('  </div>');
  }

  /// Writes the failures section of the HTML report.
  ///
  /// Organizes failures into two categories:
  /// - Tool failures (build/test execution issues)
  /// - Test failures (actual test case failures)
  ///
  /// Each failure includes:
  /// - Failure type badge
  /// - Test name
  /// - AI analysis
  /// - Recommended actions
  /// - Error details
  void _writeFailures(StringBuffer buffer) {
    if (failures.isEmpty) {
      buffer.writeln('''
        <div class="container">
          <div class="success-card">
            <h2>✅ All Tests Passed</h2>
            <p>Congratulations! All tests completed successfully.</p>
          </div>
        </div>
      ''');
      return;
    }

    buffer.writeln('<div class="container">');

    // Group failures by test class
    final toolFailures = failures.where((f) => f.testClass == 'Tool').toList();
    final testFailures = failures.where((f) => f.testClass != 'Tool').toList();

    // Write failure type tabs if we have both types
    if (toolFailures.isNotEmpty && testFailures.isNotEmpty) {
      buffer.writeln('''
        <div class="failure-type-tabs">
          <div class="failure-type-tab active" onclick="showFailures('tool')">Tool Failures (${toolFailures.length})</div>
          <div class="failure-type-tab" onclick="showFailures('test')">Test Failures (${testFailures.length})</div>
        </div>
      ''');
    }

    // Write tool failures first if any
    if (toolFailures.isNotEmpty) {
      buffer.writeln('  <h2>Tool Failures</h2>');
      for (int i = 0; i < toolFailures.length; i++) {
        _writeFailureCard(
          buffer,
          toolFailures[i],
          i < aiAnalyses.length
              ? aiAnalyses[i]
              : FailureAnalysis(
                  rootCause: 'No AI analysis available',
                  suggestedFix: 'Please check the tool failure manually',
                  additionalNotes: ['AI analysis was not performed'],
                ),
          isToolFailure: true,
        );
      }
    }

    // Write test failures
    if (testFailures.isNotEmpty) {
      buffer.writeln('  <h2>Test Failures</h2>');
      for (int i = 0; i < testFailures.length; i++) {
        _writeFailureCard(
          buffer,
          testFailures[i],
          i < aiAnalyses.length
              ? aiAnalyses[i]
              : FailureAnalysis(
                  rootCause: 'No AI analysis available',
                  suggestedFix: 'Please check the test failure manually',
                  additionalNotes: ['AI analysis was not performed'],
                ),
          isToolFailure: false,
        );
      }
    }

    buffer.writeln('</div>');
  }

  /// Writes a single failure card to the HTML report.
  ///
  /// [buffer] is the StringBuffer to write the HTML to.
  /// [failure] is the test failure to document.
  /// [analysis] is the AI analysis of the failure.
  /// [isToolFailure] indicates if this is a tool failure or test failure.
  void _writeFailureCard(
    StringBuffer buffer,
    TestFailure failure,
    FailureAnalysis analysis, {
    bool isToolFailure = false,
  }) {
    final cardClass = isToolFailure ? 'tool-error' : '';
    final badgeClass = isToolFailure ? 'tool' : 'test';
    final badgeText = isToolFailure ? 'TOOL FAILURE' : 'TEST FAILURE';

    buffer.writeln('''
      <div class="failure-card $cardClass">
        <div class="failure-header">
          <span class="failure-badge $badgeClass">$badgeText</span>
          <span class="failure-name">${_escapeHtml(failure.testName)}</span>
        </div>

        <div class="analysis-section">
          <h4>AI Analysis</h4>
          <p>${_escapeHtml(analysis.rootCause)}</p>
        </div>

        <div class="recommendations">
          <h4>Recommended Actions</h4>
          <p>${_escapeHtml(analysis.suggestedFix)}</p>
          ${_formatAdditionalNotes(analysis.additionalNotes)}
        </div>

        <details class="error-details">
          <summary>Error Details</summary>
          <pre><code>${_escapeHtml(failure.errorMessage)}
${_escapeHtml(failure.stackTrace)}</code></pre>
        </details>
      </div>
    ''');
  }

  /// Formats additional notes from the AI analysis into HTML.
  ///
  /// Returns an empty string if there are no notes.
  /// Otherwise returns an HTML list of the notes.
  String _formatAdditionalNotes(List<String>? notes) {
    if (notes == null || notes.isEmpty) {
      return '';
    }

    final items =
        notes.map((note) => '<li>${_escapeHtml(note)}</li>').join('\n');
    return '''
      <div class="additional-notes">
        <h4>Additional Notes</h4>
        <ul>
          $items
        </ul>
      </div>
    ''';
  }

  /// Escapes HTML special characters in the given text.
  ///
  /// This prevents XSS attacks and ensures proper HTML rendering.
  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}
