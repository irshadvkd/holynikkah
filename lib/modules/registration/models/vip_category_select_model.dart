class VipCategorySelectResponse {
  const VipCategorySelectResponse({
    required this.status,
    required this.message,
    this.data,
  });

  final bool status;
  final String message;
  final Map<String, dynamic>? data;

  factory VipCategorySelectResponse.fromJson(dynamic json) {
    if (json is! Map) {
      return const VipCategorySelectResponse(
        status: false,
        message: 'Invalid response',
      );
    }

    final data = json['data'];
    return VipCategorySelectResponse(
      status: json['status'] == true || json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: data is Map ? Map<String, dynamic>.from(data) : null,
    );
  }
}
