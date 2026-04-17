import 'package:flutter/material.dart';
import 'package:whatsapp_flutter/src/service/api_service.dart';
import 'package:whatsapp_flutter/src/constants/app_colors.dart';
import 'package:whatsapp_flutter/src/constants/app_text_styles.dart';

class AuthScreen extends StatefulWidget {
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final ApiService _apiService = ApiService();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  bool isLogin = true;
  bool isLoading = false;
  String? errorMessage;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final result = await _apiService.login(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (result['success']) {
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/chats',
          arguments: {
            'userId': result['userId'],
            'username': result['username'],
            'token': result['token'],
          },
        );
      }
    } else {
      setState(() {
        errorMessage = result['error'];
      });
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _handleRegister() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final result = await _apiService.register(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (result['success']) {
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/chats',
          arguments: {
            'userId': result['userId'],
            'username': result['username'],
            'token': result['token'],
          },
        );
      }
    } else {
      setState(() {
        errorMessage = result['error'];
      });
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 40),

                // LOGO Y TÍTULO
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 30),

                Text(
                  isLogin ? 'ola' : 'Crear tu cuenta',
                  style: AppTextStyles.titleLarge,
                ),
                SizedBox(height: 10),

                Text(
                  isLogin ? 'entrale al chat we' : 'Únete al chat we',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                SizedBox(height: 40),

                // CAMPO USERNAME (solo registro)
                if (!isLogin) ...[
                  _buildTextField(
                    controller: _usernameController,
                    label: 'Nombre de usuario',
                    icon: Icons.person_outline,
                    keyboardType: TextInputType.text,
                  ),
                  SizedBox(height: 16),
                ],

                // CAMPO EMAIL
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 16),

                // CAMPO PASSWORD
                _buildPasswordField(
                  controller: _passwordController,
                  label: 'Contraseña',
                ),
                SizedBox(height: 24),

                // ERROR MESSAGE
                if (errorMessage != null)
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style: TextStyle(color: Colors.red, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (errorMessage != null) SizedBox(height: 20),

                // BOTÓN LOGIN/REGISTRO
                _buildGradientButton(
                  label: isLogin ? 'Iniciar Sesión' : 'Registrarse',
                  onPressed: isLoading
                      ? null
                      : (isLogin ? _handleLogin : _handleRegister),
                  isLoading: isLoading,
                ),
                SizedBox(height: 20),

                // CAMBIAR ENTRE LOGIN Y REGISTRO
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLogin ? '¿No tienes cuenta? ' : '¿Ya tienes cuenta? ',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isLogin = !isLogin;
                          errorMessage = null;
                          _emailController.clear();
                          _passwordController.clear();
                          _usernameController.clear();
                        });
                      },
                      child: Text(
                        isLogin ? 'hazla we' : 'entrale we',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // WIDGET PARA CAMPOS DE TEXTO
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required TextInputType keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Icon(icon, color: AppColors.primaryBlue),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  // WIDGET PARA CAMPO DE CONTRASEÑA
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: _obscurePassword,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Icon(Icons.lock_outline, color: AppColors.primaryBlue),
          suffixIcon: GestureDetector(
            onTap: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
            child: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: AppColors.primaryBlue,
            ),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  // WIDGET PARA BOTÓN CON GRADIENTE
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
