/// Catalog API Client
///
/// Dio-based HTTP client for the catalog service.
/// Uses the shared [AuthInterceptor] for token management
/// and points to the catalog service base URL.
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'api_config.dart';
import 'auth_interceptor.dart';
import '../services/secure_storage_service.dart';

/// Catalog API client provider
final catalogApiClientProvider = Provider<CatalogApiClient>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return CatalogApiClient(secureStorage: secureStorage);
});

/// HTTP client for the catalog service (public endpoints)
///
/// All requests are directed at `/api/v1/public/*` routes which
/// require a valid user JWT but NOT admin role.
class CatalogApiClient {
  late final Dio _dio;

  CatalogApiClient({required SecureStorageService secureStorage}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.catalogBaseUrl,
        connectTimeout: ApiConfig.connectionTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      AuthInterceptor(
        secureStorage: secureStorage,
        authBaseUrl: ApiConfig.authBaseUrl,
      ),
      if (kDebugMode) LoggingInterceptor(),
    ]);
  }

  /// GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
