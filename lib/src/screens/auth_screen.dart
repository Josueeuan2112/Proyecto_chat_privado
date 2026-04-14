import 'package:flutter/material.dart';
import 'package:whatsapp_flutter/src/service/api_service.dart';

class AuthScreen extends StatefulWidget {
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final ApiService _apiService = ApiService();

  // Controladores para capturar texto de los campos
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  // Variables para controlar el estado
  bool isLogin = true; // true = login, false = registro
  bool isLoading = false;
  String? errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  // FUNCIÓN PARA MANEJAR LOGIN
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
      print('✅ Login exitoso');
      // Ir a la pantalla de chats
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

  // FUNCIÓN PARA MANEJAR REGISTRO
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
      print('✅ Registro exitoso');
      // Ir a la pantalla de chats
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade400, Colors.blue.shade900],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // TÍTULO
                Icon(Icons.chat_bubble, size: 80, color: Colors.white),
                SizedBox(height: 20),
                Text(
                  isLogin ? 'WhatsApp privado' : 'Crear Cuenta',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 30),

                // CAMPOS DEL FORMULARIO
                // Campo de username (solo visible si es registro)
                if (!isLogin)
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      hintText: 'Nombre de usuario',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                if (!isLogin) SizedBox(height: 15),

                // Campo de email
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                SizedBox(height: 15),

                // Campo de contraseña
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Contraseña',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                SizedBox(height: 20),

                // MENSAJE DE ERROR (si existe)
                if (errorMessage != null)
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      errorMessage!,
                      style: TextStyle(color: Colors.red.shade900),
                    ),
                  ),
                if (errorMessage != null) SizedBox(height: 20),

                // BOTÓN DE LOGIN/REGISTRO
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : (isLogin ? _handleLogin : _handleRegister),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            isLogin ? 'Iniciar Sesión' : 'Registrarse',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 20),

                // BOTÓN PARA CAMBIAR ENTRE LOGIN Y REGISTRO
                TextButton(
                  onPressed: () {
                    setState(() {
                      isLogin = !isLogin;
                      errorMessage = null;
                      _emailController.clear();
                      _passwordController.clear();
                      _usernameController.clear();
                    });
                  },
                  child: Text(
                    isLogin
                        ? '¿No tienes putito? puchale aqui zorra'
                        : '¿Ya tienes? pues entra wey',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
