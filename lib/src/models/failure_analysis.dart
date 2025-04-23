class FailureAnalysis {
  final String rootCause;
  final String suggestedFix;
  final List<String>? additionalNotes;

  FailureAnalysis({required this.rootCause, required this.suggestedFix, this.additionalNotes});

  factory FailureAnalysis.fromJson(Map<String, dynamic> json) {
    return FailureAnalysis(
      rootCause: json['root_cause'] as String,
      suggestedFix: json['suggested_fix'] as String,
      additionalNotes: (json['additional_notes'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'root_cause': rootCause,
      'suggested_fix': suggestedFix,
      if (additionalNotes != null) 'additional_notes': additionalNotes,
    };
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Root Cause: $rootCause');
    buffer.writeln('Suggested Fix: $suggestedFix');
    if (additionalNotes != null && additionalNotes!.isNotEmpty) {
      buffer.writeln('Additional Notes:');
      for (final note in additionalNotes!) {
        buffer.writeln('  - $note');
      }
    }
    return buffer.toString();
  }
}
