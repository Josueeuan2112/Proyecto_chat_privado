import 'package:http/http.dart' as http;
import 'dart:convert';
import 'image_service.dart';
import 'api_service.dart';

class ImageUploadService {
  static const String baseUrl = 'http://192.168.1.100:3000'; // ACTUALIZAR IP
  final ApiService _apiService = ApiService();
  final ImageService _imageService = ImageService();

  // SUBIR IMAGEN AL SERVIDOR Y OBTENER URL
  Future<String?> uploadImage(String base64Image) async {
    try {
      final token = await _apiService.getToken();
      if (token == null) {
        print('❌ Sin token para subir imagen');
        return null;
      }

      print('📤 Subiendo imagen al servidor...');

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/messages/upload-image'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'base64Image': base64Image}),
          )
          .timeout(
            Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Timeout subiendo imagen');
            },
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final imageUrl = data['imageUrl'];

        print('✅ Imagen subida exitosamente: $imageUrl');
        return imageUrl;
      } else {
        final error = jsonDecode(response.body);
        print('❌ Error subiendo imagen: ${error['error']}');
        return null;
      }
    } catch (e) {
      print('❌ Error en upload: $e');
      return null;
    }
  }

  // FLUJO COMPLETO: Seleccionar → Comprimir → Subir → Obtener URL
  Future<String?> selectAndUploadImage({required bool fromCamera}) async {
    try {
      // 1. Seleccionar y procesar imagen
      print('🖼️ Iniciando proceso de imagen...');
      final base64Image = await _imageService.processImageForSending(
        fromCamera: fromCamera,
      );

      if (base64Image == null) {
        print('❌ No se seleccionó imagen');
        return null;
      }

      // 2. Subir al servidor
      final imageUrl = await uploadImage(base64Image);

      return imageUrl;
    } catch (e) {
      print('❌ Error en flujo de imagen: $e');
      return null;
    }
  }
}
