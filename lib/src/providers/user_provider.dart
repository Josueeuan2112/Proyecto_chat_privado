import 'package:flutter/material.dart';
import 'package:whatsapp_flutter/src/service/api_service.dart';

class UserProvider extends ChangeNotifier {
  // Datos del usuario actual
  int? _userId;
  String? _username;
  String? _email;
  String? _token;
  bool _isLoaded = false;

  // Getters
  int? get userId => _userId;
  String? get username => _username;
  String? get email => _email;
  String? get token => _token;
  bool get isLoaded => _isLoaded;

  final ApiService _apiService = ApiService();

  // Cargar usuario después del login
  Future<void> loadUserFromLogin({
    required int userId,
    required String username,
    required String email,
    required String token,
  }) async {
    _userId = userId;
    _username = username;
    _email = email;
    _token = token;
    _isLoaded = true;

    print('✅ Usuario cargado en Provider: $_username');
    notifyListeners();
  }

  // Actualizar nombre de usuario
  Future<void> updateUsername(String newUsername) async {
    if (_username == newUsername) return;

    _username = newUsername;
    notifyListeners();

    print('✅ Username actualizado en Provider: $_username');
  }

  // Actualizar email
  Future<void> updateEmail(String newEmail) async {
    if (_email == newEmail) return;

    _email = newEmail;
    notifyListeners();

    print('✅ Email actualizado en Provider: $_email');
  }

  // Actualizar ambos (después de editar perfil)
  Future<void> updateProfile({
    required String username,
    required String email,
  }) async {
    _username = username;
    _email = email;

    notifyListeners();

    print('✅ Perfil actualizado en Provider: $_username, $_email');
  }

  // Refrescar datos del servidor
  Future<void> refreshUserFromServer() async {
    if (_userId == null) return;

    try {
      final result = await _apiService.getUserProfile(_userId!);
      if (result['success']) {
        final data = result['data'];
        _username = data['username'];
        _email = data['email'];
        notifyListeners();

        print('✅ Datos refrescados desde servidor: $_username');
      }
    } catch (e) {
      print('❌ Error refrescando datos: $e');
    }
  }

  // Limpiar (logout)
  void clearUser() {
    _userId = null;
    _username = null;
    _email = null;
    _token = null;
    _isLoaded = false;

    notifyListeners();

    print('✅ Usuario limpiado del Provider');
  }
}
