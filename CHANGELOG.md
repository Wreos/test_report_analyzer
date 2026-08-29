# Changelog

## Unreleased

- Require Dart 3.11 or later.
- Update runtime and development dependencies to their latest compatible releases.
- Remove unused `build_runner` and `mockito` development dependencies.
- Add GitHub Actions checks for formatting, analysis, tests, and package publication.
- Apply the current Dart formatter and lint recommendations without changing the public API.
- Add Android and Flutter report fixtures with parser, AI provider, output, analyzer, and CLI integration tests.
- Allow optional HTTP client injection for deterministic OpenAI and Anthropic tests.
- Prevent duplicate failures when report elements match multiple selectors and parse failure summary counts separately.
- Escape summary values in generated HTML and correctly classify setup failures.

## 1.0.0

Initial release with the following features:
- Android and Flutter test report analysis
- AI-powered insights using OpenAI or Anthropic
- Root cause analysis and suggested fixes
- HTML report generation
- Command-line interface
- Programmatic API
- Support for tool/installation failures
- Customizable report paths and flavors
