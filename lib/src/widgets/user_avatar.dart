import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class UserAvatar extends StatelessWidget {
  final String username;
  final String? imageUrl;
  final double size;

  const UserAvatar({required this.username, this.imageUrl, this.size = 56});

  // Función para generar un color basado en el nombre
  Color _getColorFromUsername(String username) {
    final colors = [
      Color(0xFF4D94FF), // Azul claro
      Color(0xFF0066CC), // Azul principal
      Color(0xFF003D99), // Azul oscuro
      Color(0xFF1976D2), // Azul acentuado
      Color(0xFF25D366), // Verde
      Color(0xFF00A6A6), // Turquesa
      Color(0xFF5C6BC0), // Índigo
    ];

    final hashCode = username.hashCode;
    return colors[hashCode % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _getColorFromUsername(username),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: imageUrl != null
          ? ClipOval(child: Image.network(imageUrl!, fit: BoxFit.cover))
          : Center(
              child: Text(
                username[0].toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: size * 0.4,
                ),
              ),
            ),
    );
  }
}
