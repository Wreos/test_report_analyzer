# Test Report Analyzer

A powerful command-line tool for analyzing Android and Flutter test reports using AI to provide insights, root cause analysis, and suggested fixes for test failures. The analyzer uses OpenAI or Anthropic APIs to generate detailed analysis of test failures, making it easier to understand and fix failing tests.
![image](https://github.com/user-attachments/assets/7a631a6c-13ff-46da-935c-9315f04d4ec1)


## Quick Start

1. Install the package globally:
```bash
dart pub global activate test_report_analyzer
```

2. Set up your API key (either OpenAI or Anthropic):
```bash
# For OpenAI
export OPENAI_API_KEY=your_key_here

# OR for Anthropic
export ANTHROPIC_API_KEY=your_key_here
```

3. Run your tests first:
```bash
# For Android tests
./gradlew connectedCheck

# For Flutter tests
flutter test
```

4. Run the analyzer:
```bash
# Using default paths
dart run test_report_analyzer

# OR with custom options
dart run test_report_analyzer \
  --reports-path path/to/reports \
  --flavor qa \
  --output analysis_report.html
```

## Features

- Analyzes Android and Flutter test reports for failures and issues
- Provides AI-powered insights into test failures
- Identifies root causes and suggests potential fixes
- Supports both OpenAI and Anthropic APIs for analysis
- Generates detailed HTML reports with failure analysis
- Handles both test failures and tool/installation failures

## Installation

You can install the package globally using:

```bash
dart pub global activate test_report_analyzer
```

Or run it directly in your project:

```bash
dart pub add test_report_analyzer
dart run test_report_analyzer
```

## Prerequisites

You'll need either an OpenAI API key or an Anthropic API key to use the analyzer. You can provide these through:
- Command line arguments: `--openai-key` or `--anthropic-key`
- Environment variables: `OPENAI_API_KEY` or `ANTHROPIC_API_KEY`

## Usage

```bash
# Show help
dart run test_report_analyzer --help

# Using default paths (for Android/Flutter projects)
dart run test_report_analyzer --openai-key YOUR_API_KEY

# With custom paths and options
dart run test_report_analyzer \
  --reports-path path/to/reports \
  --flavor qa \
  --openai-key YOUR_API_KEY \
  --output analysis_report.html

# Using environment variables
export OPENAI_API_KEY=your_key_here
dart run test_report_analyzer
```

### Command Line Options

- `--reports-path`: Path to the test reports directory (default: `build/app/reports/androidTests/connected/debug/flavors`)
- `--flavor`: Build flavor to analyze (default: `qa`)
- `--openai-key`: OpenAI API key
- `--anthropic-key`: Anthropic API key
- `--output`: Path to save the analysis report (default: `ai_analysis_report.html`)
- `--help`: Show help message
- `--version`: Show version

### Troubleshooting

1. **No test reports found**
   - Make sure you've run your tests first
   - Check if the reports directory exists at the expected path
   - Verify the flavor directory exists (e.g., `qa`, `dev`, `prod`)

2. **API Key Issues**
   - Ensure your API key is valid and has sufficient credits
   - Check if you've set the environment variable correctly
   - Try providing the key directly via command line

3. **Permission Issues**
   - Make sure you have read access to the test reports directory
   - Check if you have write permissions for the output directory

4. **Analysis Errors**
   - Check the console output for specific error messages
   - Verify the test report format matches the expected structure
   - Ensure the AI service is accessible (check network connectivity)

### Example Output

The analyzer generates both a console summary and an HTML report:

Console output:
```
Analyzing test reports...
Found 2 test failures.

Summary of findings:
Total failures analyzed: 2

Test: testLoginWithInvalidCredentials
Root cause: The test expected an "Invalid credentials" error message but received a "Network error" instead.
Suggested fix: Add proper network error handling in the login flow.

Test: testPaymentProcessing
Root cause: Payment gateway timeout after 30 seconds.
Suggested fix: Increase the timeout threshold for payment processing tests.

Analysis complete! Report saved to: /path/to/ai_analysis_report.html
```

The HTML report contains more detailed information including:
- Test failure summary
- Tool/installation failures
- AI-powered analysis for each failure including:
  - Root cause analysis
  - Suggested fixes
  - Additional insights and recommendations

### Directory Structure

The default directory structure for Android test reports:
```
build/
  app/
    reports/
      androidTests/
        connected/
          debug/
            flavors/
              qa/
                test_report.html
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
