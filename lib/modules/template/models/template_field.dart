/// Optional validation rules attached to a [TemplateField].
class TemplateValidation {
  TemplateValidation({
    this.minLength,
    this.maxLength,
    this.min,
    this.max,
    this.regex,
    this.errorMessage,
  });

  final int? minLength;
  final int? maxLength;
  final num? min;
  final num? max;
  final String? regex;
  final String? errorMessage;

  factory TemplateValidation.fromJson(Map<String, dynamic> json) {
    return TemplateValidation(
      minLength: (json['minLength'] as num?)?.toInt(),
      maxLength: (json['maxLength'] as num?)?.toInt(),
      min: json['min'] as num?,
      max: json['max'] as num?,
      regex: json['regex']?.toString(),
      errorMessage: json['errorMessage']?.toString(),
    );
  }
}

/// A single user input collected on the form page.
class TemplateField {
  TemplateField({
    required this.key,
    required this.label,
    this.hint,
    this.inputType = 'text',
    this.keyboard = 'text',
    this.required = false,
    this.defaultValue,
    this.maxLength,
    this.validation,
    this.options = const [],
  });

  final String key;
  final String label;
  final String? hint;
  final String inputType;
  final String keyboard;
  final bool required;
  final String? defaultValue;
  final int? maxLength;
  final TemplateValidation? validation;
  final List<String> options;

  factory TemplateField.fromJson(Map<String, dynamic> json) {
    final rawValidation = json['validation'];
    final rawOptions = json['options'];

    return TemplateField(
      key: (json['key'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      hint: json['hint']?.toString(),
      inputType: (json['inputType'] ?? 'text').toString(),
      keyboard: (json['keyboard'] ?? 'text').toString(),
      required: json['required'] == true,
      defaultValue: json['defaultValue']?.toString(),
      maxLength: (json['maxLength'] as num?)?.toInt(),
      validation: rawValidation is Map
          ? TemplateValidation.fromJson(
              Map<String, dynamic>.from(rawValidation),
            )
          : null,
      options: rawOptions is List
          ? rawOptions.map((e) => e.toString()).toList()
          : const [],
    );
  }
}
