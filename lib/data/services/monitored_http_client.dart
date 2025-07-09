import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';

/// Custom HTTP client that monitors network requests for performance tracking
class MonitoredHttpClient extends BaseClient {
  MonitoredHttpClient(this._inner);

  final Client _inner;

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    // Custom network monitoring is not supported for web.
    // https://firebase.google.com/docs/perf-mon/custom-network-traces?platform=android
    final metric = FirebasePerformance.instance
        .newHttpMetric(request.url.toString(), _getHttpMethod(request.method));

    // Set request payload size if available
    if (request.contentLength != null) {
      metric.requestPayloadSize = request.contentLength;
    }

    // Add custom attributes
    metric
      ..putAttribute('request_method', request.method)
      ..putAttribute('request_host', request.url.host);

    await metric.start();

    StreamedResponse response;
    try {
      response = await _inner.send(request);

      if (kDebugMode) {
        print(
          'Network request to ${request.url} completed with status: ${response.statusCode}',
        );
      }

      // Set response metrics
      metric
        ..responseContentType = response.headers['content-type'] ?? 'unknown'
        ..httpResponseCode = response.statusCode;

      if (response.contentLength != null) {
        metric.responsePayloadSize = response.contentLength;
      }

      // Add response attributes
      metric
        ..putAttribute('response_status', response.statusCode.toString())
        ..putAttribute(
          'response_success',
          (response.statusCode < 400).toString(),
        );

      // Add cache status if available
      final cacheControl = response.headers['cache-control'];
      if (cacheControl != null) {
        metric.putAttribute('cache_control', cacheControl);
      }
    } on Exception catch (e) {
      // Track errors
      metric
        ..putAttribute('error', e.toString())
        ..putAttribute('response_success', 'false');

      if (kDebugMode) {
        print('Network request to ${request.url} failed: $e');
      }

      rethrow;
    } finally {
      await metric.stop();
    }

    return response;
  }

  /// Convert string method to HttpMethod enum
  HttpMethod _getHttpMethod(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return HttpMethod.Get;
      case 'POST':
        return HttpMethod.Post;
      case 'PUT':
        return HttpMethod.Put;
      case 'DELETE':
        return HttpMethod.Delete;
      case 'HEAD':
        return HttpMethod.Head;
      case 'PATCH':
        return HttpMethod.Patch;
      case 'OPTIONS':
        return HttpMethod.Options;
      case 'CONNECT':
        return HttpMethod.Connect;
      case 'TRACE':
        return HttpMethod.Trace;
      default:
        return HttpMethod.Get; // Default fallback
    }
  }
}
