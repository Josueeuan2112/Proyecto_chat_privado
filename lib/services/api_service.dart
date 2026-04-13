import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ApiService {
  // URL de tu servidor (CAMBIAR SEGÚN TU IP LOCAL)
  // Para obtener tu IP local: en terminal escribe: ipconfig (Windows)
  // Busca "IPv4 Address" y úsala en lugar de 192.168.1.100
  static const String baseUrl = 'http://192.168.1.153:3000';

  // Guardar token en el dispositivo
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Obtener token guardado
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Limpiar token (logout)
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // FUNCIÓN PARA REGISTRARSE
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        // Guardar el token automáticamente
        await saveToken(data['token']);
        return {
          'success': true,
          'token': data['token'],
          'userId': data['userId'],
          'username': data['username'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error desconocido',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  // FUNCIÓN PARA LOGIN
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Guardar el token automáticamente
        await saveToken(data['token']);
        return {
          'success': true,
          'token': data['token'],
          'userId': data['userId'],
          'username': data['username'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error desconocido',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  // FUNCIÓN PARA OBTENER LISTA DE USUARIOS
  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final token = await getToken();
      if (token == null) {
        return [];
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/messages'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        return [];
      }
    } catch (e) {
      print('Error obteniendo usuarios: $e');
      return [];
    }
  }

  // FUNCIÓN PARA OBTENER HISTORIAL DE MENSAJES
  Future<List<Map<String, dynamic>>> getMessages(int otherUserId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return [];
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/messages/$otherUserId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        return [];
      }
    } catch (e) {
      print('Error obteniendo mensajes: $e');
      return [];
    }
  }
}
