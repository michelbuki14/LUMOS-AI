import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// REST API service for communicating with the backend
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;
  static const String baseUrl = 'http://localhost:8000';

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.next(options);
      },
      onError: (error, handler) {
        handler.next(error);
      },
    ));
  }

  // Auth
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post('/api/v1/auth/login', data: {
      'email': email,
      'password': password,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await _dio.post('/api/v1/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
    });
    return response.data;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
  }

  // Assets
  Future<List<dynamic>> getAssets({int page = 1, int limit = 50}) async {
    final response = await _dio.get('/api/v1/assets', queryParameters: {
      'page': page,
      'limit': limit,
    });
    return response.data['items'] ?? [];
  }

  Future<Map<String, dynamic>> uploadImage(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final response = await _dio.post('/api/v1/assets/upload', data: formData);
    return response.data;
  }

  Future<Map<String, dynamic>> getAsset(String assetId) async {
    final response = await _dio.get('/api/v1/assets/$assetId');
    return response.data;
  }

  Future<void> deleteAsset(String assetId) async {
    await _dio.delete('/api/v1/assets/$assetId');
  }

  // AI Operations
  Future<Map<String, dynamic>> runAiCulling(List<String> assetIds) async {
    final response = await _dio.post('/api/v1/ai/cull', data: {
      'asset_ids': assetIds,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> generateAiMask(String assetId, String maskType) async {
    final response = await _dio.post('/api/v1/ai/mask', data: {
      'asset_id': assetId,
      'mask_type': maskType,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> aiPortraitRetouch(String assetId, Map<String, dynamic> params) async {
    final response = await _dio.post('/api/v1/ai/portrait', data: {
      'asset_id': assetId,
      'params': params,
    });
    return response.data;
  }

  // Projects
  Future<List<dynamic>> getProjects() async {
    final response = await _dio.get('/api/v1/projects');
    return response.data['items'] ?? [];
  }

  Future<Map<String, dynamic>> createProject(String name, String description) async {
    final response = await _dio.post('/api/v1/projects', data: {
      'name': name,
      'description': description,
    });
    return response.data;
  }

  // Galleries
  Future<List<dynamic>> getGalleries() async {
    final response = await _dio.get('/api/v1/galleries');
    return response.data['items'] ?? [];
  }

  Future<Map<String, dynamic>> createGallery(String name, List<String> assetIds) async {
    final response = await _dio.post('/api/v1/galleries', data: {
      'name': name,
      'asset_ids': assetIds,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getGallery(String galleryId) async {
    final response = await _dio.get('/api/v1/galleries/$galleryId');
    return response.data;
  }

  Future<Map<String, dynamic>> updateGallery(String galleryId, Map<String, dynamic> data) async {
    final response = await _dio.put('/api/v1/galleries/$galleryId', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> duplicateGallery(String galleryId) async {
    final response = await _dio.post('/api/v1/galleries', data: {
      'name': 'Copy of Gallery',
      'copy_from': galleryId,
    });
    return response.data;
  }

  Future<void> closeGallery(String galleryId) async {
    await _dio.post('/api/v1/galleries/$galleryId', data: {
      'action': 'close',
    });
  }

  Future<void> deleteGallery(String galleryId) async {
    await _dio.delete('/api/v1/galleries/$galleryId');
  }

  // Batch operations
  Future<Map<String, dynamic>> startBatchProcess(Map<String, dynamic> config) async {
    final response = await _dio.post('/api/v1/batch', data: config);
    return response.data;
  }

  Future<Map<String, dynamic>> getBatchStatus(String batchId) async {
    final response = await _dio.get('/api/v1/batch/$batchId');
    return response.data;
  }
}
