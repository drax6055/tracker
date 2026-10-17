class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic errors;
  final String? code;
  final dynamic data;

  ApiException({
    required this.message,
    this.statusCode,
    this.errors,
    this.code,
    this.data,
  });

  @override
  String toString() => message;
}
