import 'package:flutter/material.dart';
import 'package:whatsapp_flutter/src/service/api_service.dart';
import 'package:whatsapp_flutter/src/service/socket_service.dart';
import 'chat_screen.dart';

class ChatsListScreen extends StatefulWidget {
  final int userId;
  final String username;
  final String token;

  const ChatsListScreen({
    required this.userId,
    required this.username,
    required this.token,
  });

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  final ApiService _apiService = ApiService();
  late SocketService _socketService;

  List<Map<String, dynamic>> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeSocket();
    _loadUsers();
  }

  // FUNCIÓN PARA INICIALIZAR SOCKET.IO
  void _initializeSocket() {
    _socketService = SocketService();

    // Conectarse al servidor Socket.io
    _socketService
        .connect(widget.token)
        .then((_) {
          print('✅ Socket conectado en ChatsListScreen');
        })
        .catchError((e) {
          print('❌ Error conectando socket: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error conectando al servidor')),
          );
        });
  }

  // FUNCIÓN PARA CARGAR USUARIOS
  Future<void> _loadUsers() async {
    print('📤 Iniciando carga de usuarios...');
    setState(() {
      isLoading = true;
    });

    try {
      final usersList = await _apiService.getUsers();

      print('✅ Usuarios recibidos: ${usersList.length}');
      print('📊 Datos: $usersList');

      if (mounted) {
        setState(() {
          users = usersList;
          isLoading = false;
        });
        print('✅ Estado actualizado. Usuarios en pantalla: ${users.length}');
      }
    } catch (e) {
      print('❌ Error cargando usuarios: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // FUNCIÓN PARA IR AL CHAT CON UN USUARIO
  void _openChat(Map<String, dynamic> user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          currentUserId: widget.userId,
          currentUsername: widget.username,
          otherUserId: user['id'],
          otherUsername: user['username'],
          socketService: _socketService,
        ),
      ),
    );
  }

  // FUNCIÓN PARA LOGOUT
  Future<void> _logout() async {
    await _apiService.clearToken();
    _socketService.disconnect();

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
    }
  }

  @override
  void dispose() {
    _socketService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chats'),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        actions: [
          PopupMenuButton(
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(child: Text('Cerrar sesión'), value: 'logout'),
            ],
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : users.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    'No hay usuarios disponibles',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loadUsers,
                    child: Text('Recargar'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  // Avatar del usuario
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade400,
                    child: Text(
                      user['username'][0].toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Nombre del usuario
                  title: Text(
                    user['username'],
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  // Email del usuario
                  subtitle: Text(user['email']),
                  // Estado (online/offline)
                  trailing: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: user['status'] == 'online'
                          ? Colors.green
                          : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  // Abrir chat al hacer clic
                  onTap: () => _openChat(user),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadUsers,
        backgroundColor: Colors.blue.shade700,
        child: Icon(Icons.refresh),
      ),
    );
  }
}
