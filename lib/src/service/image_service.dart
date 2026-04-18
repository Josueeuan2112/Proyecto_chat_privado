import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'dart:convert';

class ImageService {
  final ImagePicker _imagePicker = ImagePicker();

  // LÍMITES DE VALIDACIÓN
  static const int MAX_IMAGE_SIZE = 5 * 1024 * 1024; // 5 MB
  static const int MAX_DIMENSION = 2048;

  // SELECCIONAR IMAGEN DESDE GALERÍA
  Future<File?> pickImageFromGallery() async {
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

      final File imageFile = File(pickedFile.path);
      print('✅ Imagen seleccionada: ${pickedFile.name}');

      final fileSize = await imageFile.length();
      if (fileSize > MAX_IMAGE_SIZE) {
        print(
          '❌ Imagen muy grande: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB',
        );
        throw Exception('La imagen no debe superar 5 MB');
      }

      return imageFile;
    } catch (e) {
      print('❌ Error al seleccionar imagen: $e');
      return null;
    }
  }

  // SELECCIONAR IMAGEN DESDE CÁMARA
  Future<File?> pickImageFromCamera() async {
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

      final File imageFile = File(pickedFile.path);
      print('✅ Foto tomada: ${pickedFile.name}');

      final fileSize = await imageFile.length();
      if (fileSize > MAX_IMAGE_SIZE) {
        throw Exception('La foto no debe superar 5 MB');
      }

      return imageFile;
    } catch (e) {
      print('❌ Error al tomar foto: $e');
      return null;
    }
  }

  // COMPRIMIR IMAGEN USANDO PACKAGE IMAGE
  Future<File> compressImage(File imageFile) async {
    try {
      print('🗜️ Comprimiendo imagen...');

      // Leer la imagen original
      final bytes = await imageFile.readAsBytes();
      final originalSize = bytes.length;

      // Decodificar imagen
      final image = img.decodeImage(bytes);
      if (image == null) {
        print('⚠️ No se pudo decodificar, usando original');
        return imageFile;
      }

      // Redimensionar si es muy grande
      img.Image resized = image;
      if (image.width > MAX_DIMENSION || image.height > MAX_DIMENSION) {
        resized = img.copyResize(
          image,
          width: image.width > image.height ? MAX_DIMENSION : null,
          height: image.height > image.width ? MAX_DIMENSION : null,
          interpolation: img.Interpolation.linear,
        );
        print('📐 Redimensionado a ${resized.width}x${resized.height}');
      }

      // Codificar como JPEG con calidad 75 (muy buena compresión)
      final compressedBytes = img.encodeJpg(resized, quality: 75);
      final compressedSize = compressedBytes.length;

      // Guardar temporalmente
      final compressedFile = File(imageFile.path + '.compressed.jpg');
      await compressedFile.writeAsBytes(compressedBytes);

      print(
        '✅ Compresión completada: '
        '${(originalSize / 1024 / 1024).toStringAsFixed(2)} MB → '
        '${(compressedSize / 1024 / 1024).toStringAsFixed(2)} MB',
      );

      return compressedFile;
    } catch (e) {
      print('⚠️ Error comprimiendo, usando original: $e');
      return imageFile;
    }
  }

  // CONVERTIR IMAGEN A BASE64
  Future<String> imageToBase64(File imageFile) async {
    try {
      print('🔄 Convirtiendo imagen a Base64...');

      final bytes = await imageFile.readAsBytes();
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

  // FLUJO COMPLETO
  Future<String?> processImageForSending({required bool fromCamera}) async {
    try {
      final imageFile = fromCamera
          ? await pickImageFromCamera()
          : await pickImageFromGallery();

      if (imageFile == null) return null;

      final compressedFile = await compressImage(imageFile);
      final base64String = await imageToBase64(compressedFile);

      return base64String;
    } catch (e) {
      print('❌ Error en flujo de imagen: $e');
      return null;
    }
  }

  // CONVERTIR BASE64 A WIDGET DE IMAGEN
  static Widget base64ToImage({
    required String base64String,
    required double width,
    required double height,
  }) {
    try {
      final imageBytes = base64Decode(base64String);
      return Image.memory(
        imageBytes,
        width: width,
        height: height,
        fit: BoxFit.cover,
      );
    } catch (e) {
      print('❌ Error decodificando imagen: $e');
      return Container(
        width: width,
        height: height,
        color: Colors.grey.shade300,
        child: const Icon(Icons.broken_image, color: Colors.grey),
      );
    }
  }
}
