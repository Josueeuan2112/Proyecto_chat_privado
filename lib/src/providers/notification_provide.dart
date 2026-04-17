import 'package:flutter/material.dart';
import 'package:whatsapp_flutter/src/service/api_service.dart';

class NotificationProvider extends ChangeNotifier {
  // Mapeo: userId -> cantidad de mensajes no leídos
  Map<int, int> _unreadCounts = {};
  bool _isLoading = false;

  Map<int, int> get unreadCounts => _unreadCounts;
  bool get isLoading => _isLoading;

  int getUnreadCount(int userId) => _unreadCounts[userId] ?? 0;

  final ApiService _apiService = ApiService();

  // Cargar conteos de mensajes no leídos
  Future<void> loadUnreadCounts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.getUnreadCounts();
      if (response is Map) {
        _unreadCounts.clear();
        // Convertir las claves a int
        response.forEach((key, value) {
          final userId = int.tryParse(key.toString());
          if (userId != null) {
            _unreadCounts[userId] = value as int;
          }
        });

        print('✅ Conteos de no leídos cargados: $_unreadCounts');
      }
    } catch (e) {
      print('❌ Error cargando conteos: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Marcar mensajes como leídos
  Future<void> markAsRead(int userId) async {
    // No hacer nada si ya no hay mensajes sin leer de este usuario
    if (!_unreadCounts.containsKey(userId) || _unreadCounts[userId] == 0) {
      return;
    }

    try {
      print('📖 Intentando marcar como leído para usuario $userId...');

      await _apiService.markMessagesAsRead(userId);

      // Actualizar local inmediatamente
      _unreadCounts.remove(userId);
      notifyListeners();

      print('✅ Mensajes de usuario $userId marcados como leídos');
    } catch (e) {
      print('❌ Error marcando como leído: $e');
      // No lanzar error, solo logging
    }
  }

  // Incrementar contador (cuando llega un mensaje)
  void incrementUnreadCount(int userId) {
    _unreadCounts[userId] = (_unreadCounts[userId] ?? 0) + 1;
    notifyListeners();
  }

  // Limpiar al logout
  void clear() {
    _unreadCounts.clear();
    notifyListeners();
  }
}
