import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';

import 'api_config.dart';

class HttpService {
  static Future<Map<String, dynamic>> get(String url,
      {Map<String, String>? headers}) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: headers ?? ApiConfig.headers,
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> post(
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers ?? ApiConfig.headers,
        body: body != null ? json.encode(body) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> put(
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(url),
        headers: headers ?? ApiConfig.headers,
        body: body != null ? json.encode(body) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> delete(String url,
      {Map<String, String>? headers}) async {
    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: headers ?? ApiConfig.headers,
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> multipartPost(
    String url,
    Map<String, String> fields,
    File? file, {
    String fileField = 'photo',
  }) async {
    try {
      print('Making multipart request to: $url'); // Debug log

      var request = http.MultipartRequest('POST', Uri.parse(url));

      // CRITICAL FIX: Add authorization headers
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      if (token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
        print('Added Authorization header'); // Debug log
      } else {
        print('Warning: No auth token found!'); // Debug log
      }

      request.headers['Accept'] = 'application/json';
      // Don't set Content-Type - it's automatically set for multipart

      request.fields.addAll(fields);

      if (file != null) {
        print(
            'Adding file: ${file.path}, size: ${await file.length()} bytes'); // Debug log
        request.files
            .add(await http.MultipartFile.fromPath(fileField, file.path));
      }

      print('Sending multipart request...'); // Debug log
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}'); // Debug log
      print('Response body: ${response.body}'); // Debug log

      return _handleResponse(response);
    } catch (e) {
      print('Error in multipartPost: $e'); // Debug log
      throw Exception('Network error: $e');
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    final data = json.decode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw Exception(
          data['message'] ?? data['error'] ?? 'Unknown error occurred');
    }
  }
}
