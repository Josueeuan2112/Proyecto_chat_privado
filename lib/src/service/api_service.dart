import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ApiService {
  // URL de tu servidor (CAMBIAR SEGÚN TU IP LOCAL)
  // Para obtener tu IP local: en terminal escribe: ipconfig (Windows)
  // Busca "IPv4 Address" y úsala en lugar de 192.168.1.100
  static const String baseUrl = 'http://localhost:3000';

  // Guardar token en el dispositivo
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    print('💾 Token guardado: ${token.substring(0, 20)}...');
  }

  // Obtener token guardado
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    print(
      '🔑 Token recuperado: ${token != null ? token.substring(0, 20) + "..." : "NO HAY TOKEN"}',
    );
    return token;
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

  // FUNCIÓN PARA OBTENER PERFIL DEL USUARIO
  Future<Map<String, dynamic>> getUserProfile(int userId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'error': 'Sin token'};
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
        return {'success': false};
      }
    } catch (e) {
      print('Error obteniendo perfil: $e');
      return {'success': false};
    }
  }

  // FUNCIÓN PARA OBTENER CONTEOS DE MENSAJES NO LEÍDOS
  Future<Map<String, dynamic>> getUnreadCounts() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/messages/unread/count'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📊 Conteos recibidos: $data');
        return Map<String, dynamic>.from(data);
      } else {
        return {};
      }
    } catch (e) {
      print('❌ Error obteniendo conteos: $e');
      return {};
    }
  }

  // FUNCIÓN PARA MARCAR MENSAJES COMO LEÍDOS
  Future<void> markMessagesAsRead(int userId) async {
    try {
      final token = await getToken();
      if (token == null) {
        print('⚠️ Sin token, no se puede marcar como leído');
        return;
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/messages/mark-read'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'receiverId': userId}),
          )
          .timeout(
            Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Timeout marcando como leído');
            },
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ ${data['markedCount'] ?? 0} mensajes marcados como leídos');
      } else {
        print('⚠️ Respuesta inesperada: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error marcando como leído: $e');
      // No relanzar el error, solo logging
    }
  }
}
