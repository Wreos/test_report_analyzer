import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:test_report_analyzer/src/ai_service.dart';
import 'package:test_report_analyzer/src/models/test_failure.dart' as models;

void main() {
  final failure = models.TestFailure(
    testName: 'LoginTest.invalidCredentials',
    errorMessage: 'Expected invalid credentials',
    stackTrace: 'at LoginTest.invalidCredentials:42',
    testClass: 'LoginTest',
    testMethod: 'invalidCredentials',
  );

  http.Response openAiResponse(String content) {
    return http.Response(
      jsonEncode({
        'choices': [
          {
            'message': {'content': content},
          },
        ],
      }),
      200,
    );
  }

  http.Response anthropicResponse(String content) {
    return http.Response(
      jsonEncode({
        'content': [
          {'text': content},
        ],
      }),
      200,
    );
  }

  const validAnalysis = '''
    {
      "root_cause": "The assertion used the wrong expectation.",
      "suggested_fix": "Update the expected error message.",
      "additional_notes": ["Check the network stub."]
    }
  ''';

  group('OpenAiService', () {
    test(
      'sends the expected request and parses a successful response',
      () async {
        late http.Request capturedRequest;
        final client = MockClient((request) async {
          capturedRequest = request;
          return openAiResponse(validAnalysis);
        });
        final service = OpenAiService(
          apiKey: 'openai-secret',
          model: 'test-model',
          apiUrl: 'https://example.test/openai',
          client: client,
        );

        final analysis = await service.analyzeFailure(failure);
        final requestBody =
            jsonDecode(capturedRequest.body) as Map<String, dynamic>;

        expect(capturedRequest.url, Uri.parse('https://example.test/openai'));
        expect(
          capturedRequest.headers['authorization'],
          'Bearer openai-secret',
        );
        expect(requestBody['model'], 'test-model');
        expect(
          (requestBody['messages'] as List).last['content'],
          contains('LoginTest.invalidCredentials'),
        );
        expect(analysis.rootCause, contains('wrong expectation'));
        expect(analysis.suggestedFix, contains('expected error message'));
        expect(analysis.additionalNotes, ['Check the network stub.']);
      },
    );

    test('returns a manual fallback for invalid analysis JSON', () async {
      final service = OpenAiService(
        apiKey: 'key',
        client: MockClient((_) async => openAiResponse('not-json')),
      );

      final analysis = await service.analyzeFailure(failure);

      expect(analysis.rootCause, startsWith('Failed to parse AI response:'));
      expect(analysis.suggestedFix, contains('manually'));
    });

    test('turns API errors into a failure analysis', () async {
      final service = OpenAiService(
        apiKey: 'key',
        client: MockClient((_) async => http.Response('rate limited', 429)),
      );

      final analysis = await service.analyzeFailure(failure);

      expect(analysis.rootCause, contains('OpenAI API error: rate limited'));
      expect(analysis.additionalNotes, ['AI analysis failed due to an error']);
    });

    test('handles malformed provider response envelopes', () async {
      final service = OpenAiService(
        apiKey: 'key',
        client: MockClient((_) async => http.Response('{"choices": []}', 200)),
      );

      final analysis = await service.analyzeFailure(failure);

      expect(analysis.rootCause, startsWith('Error during AI analysis:'));
      expect(analysis.suggestedFix, contains('manually'));
    });

    test('retries transient client exceptions', () async {
      var attempts = 0;
      final service = OpenAiService(
        apiKey: 'key',
        client: MockClient((_) async {
          attempts++;
          if (attempts < 3) {
            throw http.ClientException('temporary network failure');
          }
          return openAiResponse(validAnalysis);
        }),
      );

      final analysis = await service.analyzeFailure(failure);

      expect(attempts, 3);
      expect(analysis.rootCause, contains('wrong expectation'));
    });
  });

  group('AnthropicService', () {
    test(
      'sends the expected request and parses a successful response',
      () async {
        late http.Request capturedRequest;
        final client = MockClient((request) async {
          capturedRequest = request;
          return anthropicResponse(validAnalysis);
        });
        final service = AnthropicService(
          apiKey: 'anthropic-secret',
          model: 'test-model',
          apiUrl: 'https://example.test/anthropic',
          client: client,
        );

        final analysis = await service.analyzeFailure(failure);
        final requestBody =
            jsonDecode(capturedRequest.body) as Map<String, dynamic>;

        expect(
          capturedRequest.url,
          Uri.parse('https://example.test/anthropic'),
        );
        expect(capturedRequest.headers['x-api-key'], 'anthropic-secret');
        expect(capturedRequest.headers['anthropic-version'], '2023-06-01');
        expect(requestBody['model'], 'test-model');
        expect(analysis.rootCause, contains('wrong expectation'));
      },
    );

    test('returns a manual fallback for invalid analysis JSON', () async {
      final service = AnthropicService(
        apiKey: 'key',
        client: MockClient((_) async => anthropicResponse('not-json')),
      );

      final analysis = await service.analyzeFailure(failure);

      expect(analysis.rootCause, startsWith('Failed to parse AI response:'));
      expect(analysis.suggestedFix, contains('manually'));
    });

    test('turns API errors into a failure analysis', () async {
      final service = AnthropicService(
        apiKey: 'key',
        client: MockClient((_) async => http.Response('unauthorized', 401)),
      );

      final analysis = await service.analyzeFailure(failure);

      expect(analysis.rootCause, contains('Anthropic API error: unauthorized'));
      expect(analysis.additionalNotes, ['AI analysis failed due to an error']);
    });
  });
}
