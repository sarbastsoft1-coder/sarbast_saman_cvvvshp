import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A request the backend refused, carrying the reason it gave.
///
/// The API answers errors as `{"status":"error","message":"…"}` with a 4xx,
/// which `package:http` does *not* throw on. Without this the message is only
/// visible to whoever remembers to read the body, and a rejected action looks
/// exactly like a no-op.
class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Single source of truth for talking to the backend.
///
/// Also owns the auth token lifecycle – the [GoRouter] redirect
/// reads from this so it can decide where to send the user.
class ApiService {
  // Use 10.0.2.2 if testing on Android Emulator, otherwise localhost
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api/v1',
  );

  // ── Token persistence ────────────────────────────────────────────
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('onboarding_complete');
  }

  static Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_complete') ?? false;
  }

  static Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
  }

  static Future<void> logout() async {
    try {
      await post('/auth/logout', {});
    } catch (_) {
      // Ignore errors on logout – we still clear the local token.
    }
    await clearToken();
  }

  // ── HTTP helpers ─────────────────────────────────────────────────
  static Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await http.post(
      uri,
      headers: await _getHeaders(),
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 20));
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> get(String endpoint) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await http.get(
      uri,
      headers: await _getHeaders(),
    ).timeout(const Duration(seconds: 20));
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> put(
      String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await http.put(
      uri,
      headers: await _getHeaders(),
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 20));
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await http.delete(
      uri,
      headers: await _getHeaders(),
    ).timeout(const Duration(seconds: 20));
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Multipart POST for product photos / video (`images[]`, `video_file`).
  static Future<Map<String, dynamic>> postMultipart(
    String endpoint, {
    Map<String, String> fields = const {},
    List<http.MultipartFile> files = const [],
  }) =>
      _multipart('POST', endpoint, fields: fields, files: files);

  /// Multipart update. Laravel ignores files on raw PUT, so we POST + `_method`.
  static Future<Map<String, dynamic>> putMultipart(
    String endpoint, {
    Map<String, String> fields = const {},
    List<http.MultipartFile> files = const [],
  }) =>
      _multipart(
        'POST',
        endpoint,
        fields: {...fields, '_method': 'PUT'},
        files: files,
      );

  static Future<Map<String, dynamic>> _multipart(
    String method,
    String endpoint, {
    Map<String, String> fields = const {},
    List<http.MultipartFile> files = const [],
  }) async {
    final token = await getToken();
    final request = http.MultipartRequest(method, Uri.parse('$baseUrl$endpoint'))
      ..headers.addAll({
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      })
      ..fields.addAll(fields)
      ..files.addAll(files);

    final streamed = await request.send().timeout(const Duration(seconds: 120));
    final body = await streamed.stream.bytesToString();
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } on FormatException {
      throw ApiException('The server sent a response the app could not read.');
    }
  }

  /// Build an image part for `images[]`.
  static Future<http.MultipartFile> imagePart(String path, {String field = 'images[]'}) async {
    final name = path.split(RegExp(r'[\\/]')).last;
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : 'jpg';
    final mime = switch (ext) {
      'png' => MediaType('image', 'png'),
      'webp' => MediaType('image', 'webp'),
      'gif' => MediaType('image', 'gif'),
      _ => MediaType('image', 'jpeg'),
    };
    return http.MultipartFile.fromPath(field, path, filename: name, contentType: mime);
  }

  /// Build a video part for `video_file`.
  static Future<http.MultipartFile> videoPart(String path) async {
    final name = path.split(RegExp(r'[\\/]')).last;
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : 'mp4';
    final mime = switch (ext) {
      'mov' => MediaType('video', 'quicktime'),
      'webm' => MediaType('video', 'webm'),
      'm4v' => MediaType('video', 'x-m4v'),
      _ => MediaType('video', 'mp4'),
    };
    return http.MultipartFile.fromPath('video_file', path, filename: name, contentType: mime);
  }

  // ── Error surfacing ──────────────────────────────────────────────

  /// Runs a request and throws [ApiException] unless the backend said
  /// `status: success`.
  ///
  /// Wrap anything that changes data in this so the seller sees *why* it was
  /// refused ("the courier still holds 4.50") instead of a screen that simply
  /// stops responding. Falls back to Laravel's per-field validation bag when
  /// there is no top-level message.
  static Future<Map<String, dynamic>> ensureOk(
    Future<Map<String, dynamic>> Function() request,
  ) async {
    Map<String, dynamic> body;
    try {
      body = await request();
    } on FormatException {
      throw ApiException('The server sent a response the app could not read.');
    } on http.ClientException {
      throw ApiException('Could not reach the server. Check your connection.');
    }

    if (body['status'] == 'success') return body;
    throw ApiException(_messageFrom(body));
  }

  static String _messageFrom(Map<String, dynamic> body) {
    final message = body['message']?.toString().trim();
    if (message != null && message.isNotEmpty) return message;

    final errors = body['errors'];
    if (errors is Map) {
      final flat = errors.values
          .expand((e) => e is List ? e : [e])
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .join('\n');
      if (flat.isNotEmpty) return flat;
    }

    return 'Something went wrong. Please try again.';
  }
}