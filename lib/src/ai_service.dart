import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:retry/retry.dart';
import 'models/test_failure.dart';
import 'models/failure_analysis.dart';

abstract class AiService {
  Future<FailureAnalysis> analyzeFailure(TestFailure failure);
}

class OpenAiService implements AiService {
  final String apiKey;
  final String model;
  final String apiUrl;

  OpenAiService({
    required this.apiKey,
    this.model = 'gpt-4-turbo-preview',
    this.apiUrl = 'https://api.openai.com/v1/chat/completions',
  });

  @override
  Future<FailureAnalysis> analyzeFailure(TestFailure failure) async {
    try {
      final prompt = _buildPrompt(failure);
      final response = await retry(
        () => http.post(
          Uri.parse(apiUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': model,
            'messages': [
              {
                'role': 'system',
                'content':
                    'You are a helpful test analysis assistant. Analyze test failures and provide root cause analysis and suggested fixes. Your response must be valid JSON.',
              },
              {
                'role': 'user',
                'content': prompt,
              },
            ],
            'temperature': 0.7,
            'response_format': {'type': 'json_object'},
          }),
        ),
        maxAttempts: 3,
        onRetry: (e) => print('Retrying due to error: $e'),
      );

      if (response.statusCode != 200) {
        throw Exception('OpenAI API error: ${response.body}');
      }

      final jsonResponse = jsonDecode(response.body);
      final content =
          jsonResponse['choices'][0]['message']['content'] as String;

      // Parse the content into structured analysis
      try {
        final Map<String, dynamic> analysis = jsonDecode(content);
        return FailureAnalysis.fromJson(analysis);
      } catch (e) {
        // If the response is not valid JSON, create a default analysis
        return FailureAnalysis(
          rootCause: 'Failed to parse AI response: $e',
          suggestedFix: 'Please check the test failure manually.',
          additionalNotes: [
            'AI analysis failed due to invalid response format'
          ],
        );
      }
    } catch (e) {
      return FailureAnalysis(
        rootCause: 'Error during AI analysis: $e',
        suggestedFix: 'Please check the test failure manually.',
        additionalNotes: ['AI analysis failed due to an error'],
      );
    }
  }

  String _buildPrompt(TestFailure failure) {
    return '''
Please analyze this test failure and provide a JSON response with root cause analysis and suggested fix.
The response must be valid JSON in this exact format:
{
  "root_cause": "Brief description of the root cause",
  "suggested_fix": "Detailed steps to fix the issue",
  "additional_notes": ["Optional array of additional insights or warnings"]
}

Test Failure Details:
Class: ${failure.testClass}
Method: ${failure.testMethod}
Name: ${failure.testName}
Error Message: ${failure.errorMessage}
Stack Trace:
${failure.stackTrace}
''';
  }
}

class AnthropicService implements AiService {
  final String apiKey;
  final String model;
  final String apiUrl;

  AnthropicService({
    required this.apiKey,
    this.model = 'claude-3-opus-20240229',
    this.apiUrl = 'https://api.anthropic.com/v1/messages',
  });

  @override
  Future<FailureAnalysis> analyzeFailure(TestFailure failure) async {
    try {
      final prompt = _buildPrompt(failure);
      final response = await retry(
        () => http.post(
          Uri.parse(apiUrl),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
          },
          body: jsonEncode({
            'model': model,
            'messages': [
              {
                'role': 'user',
                'content': prompt,
              },
            ],
            'temperature': 0.7,
          }),
        ),
        maxAttempts: 3,
        onRetry: (e) => print('Retrying due to error: $e'),
      );

      if (response.statusCode != 200) {
        throw Exception('Anthropic API error: ${response.body}');
      }

      final jsonResponse = jsonDecode(response.body);
      final content = jsonResponse['content'][0]['text'] as String;

      // Parse the content into structured analysis
      try {
        final Map<String, dynamic> analysis = jsonDecode(content);
        return FailureAnalysis.fromJson(analysis);
      } catch (e) {
        // If the response is not valid JSON, create a default analysis
        return FailureAnalysis(
          rootCause: 'Failed to parse AI response: $e',
          suggestedFix: 'Please check the test failure manually.',
          additionalNotes: [
            'AI analysis failed due to invalid response format'
          ],
        );
      }
    } catch (e) {
      return FailureAnalysis(
        rootCause: 'Error during AI analysis: $e',
        suggestedFix: 'Please check the test failure manually.',
        additionalNotes: ['AI analysis failed due to an error'],
      );
    }
  }

  String _buildPrompt(TestFailure failure) {
    return '''
Please analyze this test failure and provide a JSON response with root cause analysis and suggested fix.
The response must be valid JSON in this exact format:
{
  "root_cause": "Brief description of the root cause",
  "suggested_fix": "Detailed steps to fix the issue",
  "additional_notes": ["Optional array of additional insights or warnings"]
}

Test Failure Details:
Class: ${failure.testClass}
Method: ${failure.testMethod}
Name: ${failure.testName}
Error Message: ${failure.errorMessage}
Stack Trace:
${failure.stackTrace}
''';
  }
}
