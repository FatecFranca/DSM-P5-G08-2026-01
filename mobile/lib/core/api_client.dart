part of '../main.dart';

class ApiClient {
  ApiClient(this.session);

  final SessionStore session;

  Uri _uri(String path) => Uri.parse('${session.apiUrl}$path');

  Future<Map<String, dynamic>> get(String path) =>
      _send((headers) => http.get(_uri(path), headers: headers));

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) =>
      _send(
        (headers) => http.post(
          _uri(path),
          headers: headers,
          body: jsonEncode(body),
        ),
      );

  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body,
  ) =>
      _send(
        (headers) => http.patch(
          _uri(path),
          headers: headers,
          body: jsonEncode(body),
        ),
      );

  Future<void> delete(String path, {bool retried = false}) async {
    final response = await http.delete(_uri(path), headers: _headers());
    if (response.statusCode == 401 &&
        !retried &&
        session.refreshToken != null) {
      try {
        await _refreshTokens();
        return delete(path, retried: true);
      } catch (_) {
        await session.clear();
      }
    }
    if (response.statusCode >= 400) {
      final text = utf8.decode(response.bodyBytes);
      final data = text.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(text) as Map<String, dynamic>;
      throw ApiException.fromResponse(response.statusCode, data);
    }
  }

  Future<Map<String, dynamic>> _send(
    Future<http.Response> Function(Map<String, String> headers) request, {
    bool retried = false,
  }) async {
    final response = await request(_headers());
    if (response.statusCode == 401 &&
        !retried &&
        session.refreshToken != null) {
      final path = response.request?.url.path ?? '';
      if (!path.endsWith('/auth/refresh') && !path.endsWith('/auth/login')) {
        try {
          await _refreshTokens();
          return _send(request, retried: true);
        } catch (_) {
          await session.clear();
        }
      }
    }
    return _decode(response);
  }

  Future<void> _refreshTokens() async {
    final response = await http.post(
      _uri('/auth/refresh'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': session.refreshToken}),
    );
    final data = _decode(response);
    await session.saveAuth(data);
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
