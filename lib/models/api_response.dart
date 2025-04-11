class ApiResponse {
  final bool success;
  final String message;
  final Map<String, dynamic> data;

  ApiResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ApiResponse.success(Map<String, dynamic> data) {
    return ApiResponse(
      success: true,
      message: data['message'] ?? 'Success',
      data: data,
    );
  }

  factory ApiResponse.error(String message) {
    return ApiResponse(
      success: false,
      message: message,
      data: {},
    );
  }
}
