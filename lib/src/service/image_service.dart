import 'package:image_picker/image_picker.dart';
import 'dart:convert';

class ImageService {
  final ImagePicker _imagePicker = ImagePicker();

  // LÍMITES DE VALIDACIÓN
  static const int MAX_IMAGE_SIZE = 10 * 1024 * 1024; // 10 MB

  // SELECCIONAR IMAGEN DESDE GALERÍA
  Future<XFile?> pickImageFromGallery() async {
    try {
      print('📱 Abriendo galería...');

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        print('⚠️ Usuario canceló la selección');
        return null;
      }

      print('✅ Imagen seleccionada: ${pickedFile.name}');

      final fileSize = await pickedFile.length();
      if (fileSize > MAX_IMAGE_SIZE) {
        print(
          '❌ Imagen muy grande: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB',
        );
        throw Exception('La imagen no debe superar 10 MB');
      }

      return pickedFile;
    } catch (e) {
      print('❌ Error al seleccionar imagen: $e');
      return null;
    }
  }

  // SELECCIONAR IMAGEN DESDE CÁMARA
  Future<XFile?> pickImageFromCamera() async {
    try {
      print('📷 Abriendo cámara...');

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        print('⚠️ Usuario canceló la foto');
        return null;
      }

      print('✅ Foto tomada: ${pickedFile.name}');

      final fileSize = await pickedFile.length();
      if (fileSize > MAX_IMAGE_SIZE) {
        throw Exception('La foto no debe superar 10 MB');
      }

      return pickedFile;
    } catch (e) {
      print('❌ Error al tomar foto: $e');
      return null;
    }
  }

  // CONVERTIR XFILE A BASE64
  Future<String> xfileToBase64(XFile xfile) async {
    try {
      print('🔄 Convirtiendo imagen a Base64...');

      // Leer directamente de XFile, no de File
      final bytes = await xfile.readAsBytes();
      final base64String = base64Encode(bytes);

      print(
        '✅ Base64 generado: ${(base64String.length / 1024).toStringAsFixed(2)} KB',
      );

      return base64String;
    } catch (e) {
      print('❌ Error convirtiendo a Base64: $e');
      throw Exception('Error al procesar imagen');
    }
  }

  // FLUJO COMPLETO: Seleccionar → Base64
  Future<String?> processImageForSending({required bool fromCamera}) async {
    try {
      print('🖼️ Iniciando proceso de imagen...');

      final xfile = fromCamera
          ? await pickImageFromCamera()
          : await pickImageFromGallery();

      if (xfile == null) {
        print('❌ No se seleccionó imagen');
        return null;
      }

      // Convertir directamente a Base64
      final base64String = await xfileToBase64(xfile);

      print('✅ Imagen procesada y lista para enviar');
      return base64String;
    } catch (e) {
      print('❌ Error en flujo de imagen: $e');
      return null;
    }
  }
}
