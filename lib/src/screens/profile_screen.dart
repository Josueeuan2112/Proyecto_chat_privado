import 'package:flutter/material.dart';
import 'package:whatsapp_flutter/src/constants/app_colors.dart';
import 'package:whatsapp_flutter/src/constants/app_text_styles.dart';
import 'package:whatsapp_flutter/src/widgets/user_avatar.dart';
import 'edit_profile_screen.dart';
import 'change_photo_screen.dart';

class ProfileScreen extends StatefulWidget {
  final int userId;
  final String username;
  final String email;
  final bool isOwnProfile;
  final String? status;

  const ProfileScreen({
    required this.userId,
    required this.username,
    required this.email,
    this.isOwnProfile = false,
    this.status,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String _currentUsername;
  late String _currentEmail;

  @override
  void initState() {
    super.initState();
    _currentUsername = widget.username;
    _currentEmail = widget.email;
  }

  void _onProfileUpdated() {
    // Este callback se llamará cuando se actualice el perfil
    // Puedes refrescar los datos aquí
  }

  void _openEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          userId: widget.userId,
          currentUsername: _currentUsername,
          currentEmail: _currentEmail,
          onProfileUpdated: _onProfileUpdated,
        ),
      ),
    ).then((result) {
      if (result != null && result is Map<String, dynamic>) {
        print('✅ Datos actualizados: $result');
        setState(() {
          _currentUsername = result['username'] ?? _currentUsername;
          _currentEmail = result['email'] ?? _currentEmail;
        });

        // Mostrar confirmación
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Perfil actualizado correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _openChangePhoto() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangePhotoScreen(
          username: _currentUsername,
          onPhotoSelected: () {
            // Callback cuando se selecciona foto
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = widget.status == 'online';

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Perfil', style: AppTextStyles.titleMedium),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // SECCIÓN DE AVATAR Y ESTADO
            Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  // AVATAR GRANDE CON BADGE
                  Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 16,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: UserAvatar(
                          username: _currentUsername,
                          size: 120,
                        ),
                      ),
                      // INDICADOR DE ESTADO
                      if (!widget.isOwnProfile)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isOnline
                                  ? AppColors.successGreen
                                  : Colors.grey.shade400,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),

                      // BADGE "MI PERFIL" (solo si es perfil propio)
                      if (widget.isOwnProfile)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Mi Perfil',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // NOMBRE DE USUARIO
                  Text(
                    _currentUsername,
                    style: AppTextStyles.titleMedium.copyWith(fontSize: 28),
                  ),
                  SizedBox(height: 8),

                  // ESTADO
                  if (!widget.isOwnProfile)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isOnline
                            ? AppColors.successGreen.withOpacity(0.1)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isOnline
                              ? AppColors.successGreen.withOpacity(0.3)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isOnline
                                  ? AppColors.successGreen
                                  : Colors.grey.shade400,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            isOnline ? 'En línea' : 'Desconectado',
                            style: TextStyle(
                              color: isOnline
                                  ? AppColors.successGreen
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // SECCIÓN DE INFORMACIÓN
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  _buildInfoTile(
                    icon: Icons.mail_outline,
                    label: 'Email',
                    value: _currentEmail,
                  ),
                  Divider(height: 1, indent: 56),
                  _buildInfoTile(
                    icon: Icons.person_outline,
                    label: 'Usuario ID',
                    value: '#${widget.userId}',
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // BOTONES DE ACCIÓN
            if (widget.isOwnProfile) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildActionButton(
                      label: 'Editar Perfil',
                      icon: Icons.edit,
                      onPressed: _openEditProfile,
                    ),
                    SizedBox(height: 12),
                    _buildActionButton(
                      label: 'Cambiar Foto',
                      icon: Icons.camera_alt,
                      onPressed: _openChangePhoto,
                    ),
                  ],
                ),
              ),
            ] else ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: _buildActionButton(
                  label: 'Enviar Mensaje',
                  icon: Icons.message,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],

            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryBlue),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption),
                SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.bodyText.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: AppColors.buttonGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.successGreen.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white),
              SizedBox(width: 8),
              Text(label, style: AppTextStyles.buttonText),
            ],
          ),
        ),
      ),
    );
  }
}
