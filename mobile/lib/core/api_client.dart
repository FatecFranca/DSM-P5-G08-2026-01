part of '../main.dart';

class ApiClient {
  ApiClient(this.session);

  final SessionStore session;

  Uri _uri(String path) => Uri.parse('${session.apiUrl}$path');

  Future<Map<String, dynamic>> get(String path) async {
    final response = await http.get(_uri(path), headers: _headers());
    return _decode(response);
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      _uri(path),
      headers: _headers(),
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http.patch(
      _uri(path),
      headers: _headers(),
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json',
      if (session.accessToken != null)
        'Authorization': 'Bearer ${session.accessToken}',
    };
  }

  Map<String, dynamic> _decode(http.Response response) {
    final text = utf8.decode(response.bodyBytes);
    final data = text.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(text) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw ApiException.fromResponse(response.statusCode, data);
    }
    return data;
  }
}

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.details});

  final String message;
  final int? statusCode;
  final Object? details;

  factory ApiException.fromResponse(int statusCode, Map<String, dynamic> data) {
    final details = data['details'];
    final baseMessage =
        data['error']?.toString() ??
        data['message']?.toString() ??
        _fallbackMessage(statusCode);
    final detailMessage = _detailsMessage(details);
    return ApiException(
      detailMessage == null ? baseMessage : '$baseMessage: $detailMessage',
      statusCode: statusCode,
      details: details,
    );
  }

  @override
  String toString() => message;
}
