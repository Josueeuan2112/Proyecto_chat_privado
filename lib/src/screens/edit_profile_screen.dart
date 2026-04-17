import 'package:flutter/material.dart';
import 'package:whatsapp_flutter/src/service/user_service.dart';
import 'package:whatsapp_flutter/src/constants/app_colors.dart';
import 'package:whatsapp_flutter/src/constants/app_text_styles.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class EditProfileScreen extends StatefulWidget {
  final int userId;
  final String currentUsername;
  final String currentEmail;
  final VoidCallback onProfileUpdated;

  const EditProfileScreen({
    required this.userId,
    required this.currentUsername,
    required this.currentEmail,
    required this.onProfileUpdated,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final UserService _userService = UserService();
  late TextEditingController _usernameController;
  late TextEditingController _emailController;

  bool isLoading = false;
  String? errorMessage;
  String? successMessage;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.currentUsername);
    _emailController = TextEditingController(text: widget.currentEmail);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_usernameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty) {
      setState(() {
        errorMessage = 'Todos los campos son obligatorios';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      successMessage = null;
    });

    final result = await _userService.updateProfile(
      userId: widget.userId,
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
    );

    if (mounted) {
      setState(() {
        isLoading = false;
      });

      if (result['success']) {
        setState(() {
          successMessage = 'Perfil actualizado exitosamente';
        });

        // Actualizar el Provider con los nuevos datos
        if (mounted) {
          await context.read<UserProvider>().updateProfile(
            username: _usernameController.text.trim(),
            email: _emailController.text.trim(),
          );
        }

        Future.delayed(Duration(seconds: 2), () {
          Navigator.pop(context, {
            'username': _usernameController.text.trim(),
            'email': _emailController.text.trim(),
          });
        });
      } else {
        setState(() {
          errorMessage = result['error'] ?? 'Error al actualizar';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Editar Perfil', style: AppTextStyles.titleMedium),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            // TÍTULO
            Text(
              'Actualiza tu información',
              style: AppTextStyles.titleMedium.copyWith(fontSize: 20),
            ),
            SizedBox(height: 32),

            // CAMPO USERNAME
            _buildTextField(
              controller: _usernameController,
              label: 'Nombre de usuario',
              icon: Icons.person_outline,
              hint: 'Ej: juan123',
            ),
            SizedBox(height: 16),

            // CAMPO EMAIL
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.mail_outline,
              hint: 'Ej: tu@email.com',
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 24),

            // MENSAJES
            if (errorMessage != null)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            if (errorMessage != null) SizedBox(height: 16),

            if (successMessage != null)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        successMessage!,
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
            if (successMessage != null) SizedBox(height: 16),

            // BOTÓN GUARDAR
            _buildGradientButton(
              label: isLoading ? 'Guardando...' : 'Guardar Cambios',
              onPressed: isLoading ? null : _saveChanges,
              isLoading: isLoading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.primaryBlue),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required String label,
    required VoidCallback? onPressed,
    required bool isLoading,
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
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : Text(label, style: AppTextStyles.buttonText),
          ),
        ),
      ),
    );
  }
}
