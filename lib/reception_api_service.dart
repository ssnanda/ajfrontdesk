import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'app_config.dart';
import 'checkin_request.dart';
import 'checkin_response.dart';
import 'reception_host.dart';
import 'visitor.dart';

class ReceptionApiService {
  ReceptionApiService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;
  static const Duration _requestTimeout = Duration(seconds: 12);

  Uri _buildUri(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('${AppConfig.siteUrl}$normalizedPath');
  }

  /// Every request proves itself with this iPad's device key (it only unlocks the reception endpoints).
  Map<String, String> get _headers => {
    'X-AJCore-Device-Key': AppConfig.deviceKey,
    'Accept': 'application/json',
  };

  /// Checks a site URL + device key; returns the site name for the welcome screen.
  static Future<({String siteName, String deviceName})> ping(String siteUrl, String deviceKey) async {
    final res = await http.get(
      Uri.parse('$siteUrl/reception/ping'),
      headers: {'X-AJCore-Device-Key': deviceKey, 'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 12));
    final body = res.body.isEmpty ? <String, dynamic>{} : jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw Exception((body['message'] as String?) ?? 'The site rejected that device key.');
    }
    return (siteName: (body['site_name'] ?? '') as String, deviceName: (body['device_name'] ?? '') as String);
  }

  Future<List<ReceptionHost>> searchHosts(String query) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return const [];
    }

    final response = await _sendRequest(
      () => _client.get(
        _buildUri(
          '/reception/hosts/search',
        ).replace(queryParameters: {'q': normalizedQuery}),
        headers: _headers,
      ),
      fallback: 'Unable to search hosts right now. Please try again.',
    );
    if (response.statusCode != 200) {
      throw Exception(
        _readErrorMessage(response.body, fallback: 'Unable to search hosts.'),
      );
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final results = payload['results'] as List<dynamic>? ?? const [];
    return results
        .map((item) => ReceptionHost.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<ReceptionHost>> getHosts() async {
    final response = await _sendRequest(
      () => _client.get(_buildUri('/reception/hosts'), headers: _headers),
      fallback: 'Unable to load hosts right now. Please try again.',
    );
    if (response.statusCode != 200) {
      throw Exception(
        _readErrorMessage(response.body, fallback: 'Unable to load hosts.'),
      );
    }

    final payload = (jsonDecode(response.body) as Map<String, dynamic>)['hosts'] as List<dynamic>? ?? const [];
    return payload
        .map((item) => ReceptionHost.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Visitor?> lookupByPhone(String phone) async {
    final response = await _sendRequest(
      () => _client.post(
        _buildUri('/reception/lookup-by-phone'),
        headers: {..._headers, 'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      ),
      fallback:
          'Unable to reach reception services right now. Please try again.',
    );

    if (response.statusCode != 200) {
      throw Exception(
        _readErrorMessage(response.body, fallback: 'Lookup failed.'),
      );
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final found = payload['found'] as bool? ?? false;
    if (!found) {
      return null;
    }
    return Visitor.fromLookupJson(payload);
  }

  Future<CheckInResponse> checkIn(CheckInRequest request) async {
    try {
      final response = await _sendRequest(
        () => _client.post(
          _buildUri('/reception/check-in'),
          headers: {..._headers, 'Content-Type': 'application/json'},
          body: jsonEncode(request.toJson()),
        ),
        fallback: 'Unable to complete check-in right now. Please try again.',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return CheckInResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }

      return CheckInResponse(
        success: false,
        message: _readErrorMessage(response.body, fallback: 'Check-in failed.'),
      );
    } on FormatException {
      return const CheckInResponse(
        success: false,
        message:
            'The server returned an unexpected response. Please try again.',
      );
    } on Exception catch (error) {
      return CheckInResponse(
        success: false,
        message: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<http.Response> _sendRequest(
    Future<http.Response> Function() request, {
    required String fallback,
  }) async {
    try {
      final response = await request().timeout(_requestTimeout);
      return response;
    } on SocketException {
      throw Exception(
        'Unable to connect to the front desk server. Please check the network and try again.',
      );
    } on TimeoutException {
      throw Exception(
        'The server is taking too long to respond. Please try again.',
      );
    } on http.ClientException {
      throw Exception(fallback);
    } on FormatException {
      throw Exception(
        'The server returned an unexpected response. Please try again.',
      );
    } catch (_) {
      throw Exception(fallback);
    }
  }

  String _readErrorMessage(String body, {required String fallback}) {
    try {
      final payload = jsonDecode(body);
      if (payload is Map<String, dynamic>) {
        final detail = payload['detail'];
        if (detail is String && detail.isNotEmpty) {
          return detail;
        }
        if (detail is List && detail.isNotEmpty) {
          final first = detail.first;
          if (first is Map<String, dynamic>) {
            final message = first['msg'];
            if (message is String && message.isNotEmpty) {
              return message;
            }
          }
        }
        final message = payload['message'];
        if (message is String && message.isNotEmpty) {
          return message;
        }
      }
    } catch (_) {
      // Ignore JSON parsing errors and fall back to a generic message.
    }
    return fallback;
  }
}
