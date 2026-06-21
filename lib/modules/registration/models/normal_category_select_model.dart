class NormalCategorySelectResponse {
  const NormalCategorySelectResponse({
    required this.status,
    required this.message,
    this.data,
  });

  final bool status;
  final String message;
  final Map<String, dynamic>? data;

  factory NormalCategorySelectResponse.fromJson(dynamic json) {
    if (json is! Map) {
      return const NormalCategorySelectResponse(
        status: false,
        message: 'Invalid response',
      );
    }

    final data = json['data'];
    return NormalCategorySelectResponse(
      status: json['status'] == true || json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: data is Map ? Map<String, dynamic>.from(data) : null,
    );
  }
}
