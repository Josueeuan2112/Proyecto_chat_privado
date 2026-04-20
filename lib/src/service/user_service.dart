import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_service.dart';

class UserService {
  static const String baseUrl = 'http://localhost:3000';
  final ApiService _apiService = ApiService();

  // Actualizar perfil (username y email)
  Future<Map<String, dynamic>> updateProfile({
    required int userId,
    required String username,
    required String email,
  }) async {
    try {
      final token = await _apiService.getToken();
      if (token == null) {
        return {'success': false, 'error': 'No hay token de autenticación'};
      }

      final response = await http.put(
        Uri.parse('$baseUrl/api/auth/profile/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'username': username, 'email': email}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['mensaje'] ?? 'Perfil actualizado',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error al actualizar perfil',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  // Obtener información del usuario
  Future<Map<String, dynamic>> getUserInfo(int userId) async {
    try {
      final token = await _apiService.getToken();
      if (token == null) {
        return {'success': false, 'error': 'No hay token de autenticación'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/profile/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'error': 'Error al obtener información del usuario',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }
}
