import 'dart:io';
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

/// Configuration for the test report analyzer
@immutable
class Config {
  final String openAiApiKey;
  final String openAiModel;
  final String openAiApiUrl;
  final String anthropicApiKey;
  final String anthropicModel;
  final String anthropicApiUrl;
  final int timeout;
  final int maxRetries;
  final int retryDelay;
  final String logLevel;
  final String outputDirectory;

  const Config({
    required this.openAiApiKey,
    this.openAiModel = 'gpt-4-turbo-preview',
    this.openAiApiUrl = 'https://api.openai.com/v1/chat/completions',
    required this.anthropicApiKey,
    this.anthropicModel = 'claude-3-opus-20240229',
    this.anthropicApiUrl = 'https://api.anthropic.com/v1/messages',
    this.timeout = 30,
    this.maxRetries = 3,
    this.retryDelay = 1,
    this.logLevel = 'INFO',
    this.outputDirectory = 'output',
  });

  /// Creates a configuration from environment variables
  factory Config.fromEnvironment() {
    final openAiApiKey = Platform.environment['OPENAI_API_KEY'];
    if (openAiApiKey == null) {
      throw ConfigError('OPENAI_API_KEY environment variable is not set');
    }

    final anthropicApiKey = Platform.environment['ANTHROPIC_API_KEY'];
    if (anthropicApiKey == null) {
      throw ConfigError('ANTHROPIC_API_KEY environment variable is not set');
    }

    final openAiModel = Platform.environment['OPENAI_MODEL'];
    final openAiApiUrl = Platform.environment['OPENAI_API_URL'];
    final anthropicModel = Platform.environment['ANTHROPIC_MODEL'];
    final anthropicApiUrl = Platform.environment['ANTHROPIC_API_URL'];
    final timeoutStr = Platform.environment['TIMEOUT'];
    final maxRetriesStr = Platform.environment['MAX_RETRIES'];
    final retryDelayStr = Platform.environment['RETRY_DELAY'];
    final logLevel = Platform.environment['LOG_LEVEL'];
    final outputDirectory = Platform.environment['OUTPUT_DIRECTORY'];

    return Config.validated(
      openAiApiKey: openAiApiKey,
      openAiModel: openAiModel ?? 'gpt-4-turbo-preview',
      openAiApiUrl: openAiApiUrl ?? 'https://api.openai.com/v1/chat/completions',
      anthropicApiKey: anthropicApiKey,
      anthropicModel: anthropicModel ?? 'claude-3-opus-20240229',
      anthropicApiUrl: anthropicApiUrl ?? 'https://api.anthropic.com/v1/messages',
      timeout: int.tryParse(timeoutStr ?? '') ?? 30,
      maxRetries: int.tryParse(maxRetriesStr ?? '') ?? 3,
      retryDelay: int.tryParse(retryDelayStr ?? '') ?? 1,
      logLevel: logLevel ?? 'INFO',
      outputDirectory: outputDirectory ?? 'output',
    );
  }

  /// Creates a configuration from a YAML file
  factory Config.fromYaml(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      throw ConfigError('Configuration file not found: $path');
    }

    final yamlString = file.readAsStringSync();
    final yaml = loadYaml(yamlString) as Map;

    final openai = yaml['openai'] as Map? ?? {};
    final anthropic = yaml['anthropic'] as Map? ?? {};

    return Config(
      openAiApiKey: openai['api_key']?.toString() ?? '',
      openAiModel: openai['model']?.toString() ?? 'gpt-4-turbo-preview',
      openAiApiUrl: openai['api_url']?.toString() ?? 'https://api.openai.com/v1/chat/completions',
      anthropicApiKey: anthropic['api_key']?.toString() ?? '',
      anthropicModel: anthropic['model']?.toString() ?? 'claude-3-opus-20240229',
      anthropicApiUrl: anthropic['api_url']?.toString() ?? 'https://api.anthropic.com/v1/messages',
      timeout: yaml['timeout'] as int? ?? 30,
      maxRetries: yaml['max_retries'] as int? ?? 3,
      retryDelay: yaml['retry_delay'] as int? ?? 1,
      logLevel: yaml['log_level']?.toString() ?? 'INFO',
      outputDirectory: yaml['output_directory']?.toString() ?? 'output',
    );
  }

  /// Validates the configuration
  void validate() {
    if (openAiApiKey.isEmpty) {
      throw ConfigError('OpenAI API key is required');
    }
    if (anthropicApiKey.isEmpty) {
      throw ConfigError('Anthropic API key is required');
    }
    if (timeout <= 0) {
      throw ConfigError('Timeout must be positive');
    }
    if (maxRetries < 0) {
      throw ConfigError('Max retries cannot be negative');
    }
    if (retryDelay <= 0) {
      throw ConfigError('Retry delay must be positive');
    }
    if (!['DEBUG', 'INFO', 'WARN', 'ERROR'].contains(logLevel.toUpperCase())) {
      throw ConfigError('Invalid log level: $logLevel');
    }
  }

  /// Creates a copy of the configuration with some fields replaced
  Config copyWith({
    String? openAiApiKey,
    String? openAiModel,
    String? openAiApiUrl,
    String? anthropicApiKey,
    String? anthropicModel,
    String? anthropicApiUrl,
    int? timeout,
    int? maxRetries,
    int? retryDelay,
    String? logLevel,
    String? outputDirectory,
  }) {
    return Config(
      openAiApiKey: openAiApiKey ?? this.openAiApiKey,
      openAiModel: openAiModel ?? this.openAiModel,
      openAiApiUrl: openAiApiUrl ?? this.openAiApiUrl,
      anthropicApiKey: anthropicApiKey ?? this.anthropicApiKey,
      anthropicModel: anthropicModel ?? this.anthropicModel,
      anthropicApiUrl: anthropicApiUrl ?? this.anthropicApiUrl,
      timeout: timeout ?? this.timeout,
      maxRetries: maxRetries ?? this.maxRetries,
      retryDelay: retryDelay ?? this.retryDelay,
      logLevel: logLevel ?? this.logLevel,
      outputDirectory: outputDirectory ?? this.outputDirectory,
    );
  }

  factory Config.validated({
    required String openAiApiKey,
    String openAiModel = 'gpt-4-turbo-preview',
    String openAiApiUrl = 'https://api.openai.com/v1/chat/completions',
    required String anthropicApiKey,
    String anthropicModel = 'claude-3-opus-20240229',
    String anthropicApiUrl = 'https://api.anthropic.com/v1/messages',
    int timeout = 30,
    int maxRetries = 3,
    int retryDelay = 1,
    String logLevel = 'INFO',
    String outputDirectory = 'output',
  }) {
    final config = Config(
      openAiApiKey: openAiApiKey,
      openAiModel: openAiModel,
      openAiApiUrl: openAiApiUrl,
      anthropicApiKey: anthropicApiKey,
      anthropicModel: anthropicModel,
      anthropicApiUrl: anthropicApiUrl,
      timeout: timeout,
      maxRetries: maxRetries,
      retryDelay: retryDelay,
      logLevel: logLevel,
      outputDirectory: outputDirectory,
    );
    config.validate();
    return config;
  }
}

class ConfigError implements Exception {
  final String message;
  ConfigError(this.message);
  @override
  String toString() => 'ConfigError: $message';
}
