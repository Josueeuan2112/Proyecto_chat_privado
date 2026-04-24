import 'package:flutter/material.dart';
import 'package:whatsapp_flutter/src/providers/notification_provide.dart';
import 'package:whatsapp_flutter/src/screens/profile_screen.dart';
import 'package:whatsapp_flutter/src/service/api_service.dart';
import 'package:whatsapp_flutter/src/service/socket_service.dart';
import 'package:whatsapp_flutter/src/constants/app_colors.dart';
import 'package:whatsapp_flutter/src/constants/app_text_styles.dart';
import 'package:whatsapp_flutter/src/widgets/user_avatar.dart';
import 'chat_screen.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

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
  List<Map<String, dynamic>> filteredUsers = [];
  bool isLoading = true;
  TextEditingController _searchController = TextEditingController();
  String? _currentUserEmail;

  @override
  void initState() {
    super.initState();
    _initializeSocket();
    _loadUsers();
    _loadCurrentUserEmail();
    _searchController.addListener(_filterUsers);

    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        context.read<NotificationProvider>().loadUnreadCounts();
      }
    });
  }

  Future<void> _loadCurrentUserEmail() async {
    try {
      final userInfo = await _apiService.getUserProfile(widget.userId);
      if (userInfo['success'] && mounted) {
        setState(() {
          _currentUserEmail = userInfo['data']['email'];
        });
      }
    } catch (e) {
      print('Error cargando email del usuario: $e');
    }
  }

  void _initializeSocket() {
    _socketService = SocketService();

    _socketService
        .connect(widget.token)
        .then((_) {
          print('✅ Socket conectado en ChatsListScreen');
        })
        .catchError((e) {
          print('❌ Error conectando socket: $e');
          _showErrorSnackBar('Error conectando al servidor');
        });
  }

  Future<void> _loadUsers() async {
    setState(() {
      isLoading = true;
    });

    final usersList = await _apiService.getUsers();

    if (mounted) {
      setState(() {
        users = usersList;
        filteredUsers = usersList;
        isLoading = false;
      });
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      if (query.isEmpty) {
        filteredUsers = users;
      } else {
        filteredUsers = users
            .where(
              (user) =>
                  user['username'].toLowerCase().contains(query) ||
                  user['email'].toLowerCase().contains(query),
            )
            .toList();
      }
    });
  }

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

  Future<void> _logout() async {
    // Mostrar confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cerrar sesión'),
        content: Text('¿Seguro que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _apiService.clearToken();
      _socketService.disconnect();

      if (mounted) {
        context.read<UserProvider>().clearUser();
        Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _socketService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Consumer<UserProvider>(
          builder: (context, userProvider, _) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(
                      userId: userProvider.userId ?? widget.userId,
                      username: userProvider.username ?? widget.username,
                      email:
                          userProvider.email ??
                          _currentUserEmail ??
                          'cargando...',
                      isOwnProfile: true,
                      status: 'online',
                      socketService: _socketService,
                    ),
                  ),
                ).then((_) {
                  _loadUsers();
                });
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mensajes', style: AppTextStyles.titleMedium),
                  Text(
                    'Conectado como ${userProvider.username ?? widget.username}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.groups, color: AppColors.primaryBlue),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/groups',
                arguments: {
                  'userId': widget.userId,
                  'socketService': _socketService,
                },
              );
            },
            tooltip: 'Grupos',
          ),
          PopupMenuButton(
            icon: Icon(Icons.more_vert, color: AppColors.primaryBlue),
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red, size: 20),
                    SizedBox(width: 12),
                    Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
                  ],
                ),
                value: 'logout',
              ),
            ],
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // BARRA DE BÚSQUEDA
          Padding(
            padding: EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar usuario...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: Icon(Icons.search, color: AppColors.primaryBlue),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),

          // LISTA DE USUARIOS
          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(AppColors.primaryBlue),
                    ),
                  )
                : filteredUsers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        SizedBox(height: 20),
                        Text(
                          _searchController.text.isEmpty
                              ? 'No hay usuarios disponibles'
                              : 'No se encontraron resultados',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        if (_searchController.text.isEmpty)
                          SizedBox(height: 20),
                        if (_searchController.text.isEmpty)
                          ElevatedButton.icon(
                            onPressed: _loadUsers,
                            icon: Icon(Icons.refresh),
                            label: Text('Recargar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                            ),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      final isOnline = user['status'] == 'online';

                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Consumer<NotificationProvider>(
                          builder: (context, notificationProvider, _) {
                            final unreadCount = notificationProvider
                                .getUnreadCount(user['id']);

                            return Container(
                              decoration: BoxDecoration(
                                color: unreadCount > 0
                                    ? AppColors.primaryBlue.withOpacity(0.05)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: unreadCount > 0
                                    ? Border.all(
                                        color: AppColors.primaryBlue
                                            .withOpacity(0.2),
                                        width: 1,
                                      )
                                    : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _openChat(user),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        // AVATAR CON ESTADO
                                        Stack(
                                          children: [
                                            UserAvatar(
                                              username: user['username'],
                                              size: 56,
                                            ),
                                            // Indicador online/offline
                                            Positioned(
                                              bottom: 0,
                                              right: 0,
                                              child: Container(
                                                width: 16,
                                                height: 16,
                                                decoration: BoxDecoration(
                                                  color: isOnline
                                                      ? AppColors.successGreen
                                                      : Colors.grey.shade400,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 2,
                                                  ),
                                                ),
                                              ),
                                            ),

                                            // BADGE DE MENSAJES NO LEÍDOS
                                            if (unreadCount > 0)
                                              Positioned(
                                                top: 0,
                                                right: 0,
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                    border: Border.all(
                                                      color: Colors.white,
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    unreadCount > 9
                                                        ? '9+'
                                                        : unreadCount
                                                              .toString(),
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        SizedBox(width: 16),

                                        // INFORMACIÓN DEL USUARIO
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                user['username'],
                                                style: AppTextStyles.titleMedium
                                                    .copyWith(fontSize: 16),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                user['email'],
                                                style: AppTextStyles.caption,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),

                                        // FLECHA O BADGE
                                        if (unreadCount == 0)
                                          Icon(
                                            Icons.chevron_right,
                                            color: AppColors.primaryBlue,
                                          )
                                        else
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              unreadCount > 99
                                                  ? '99+'
                                                  : unreadCount.toString(),
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadUsers,
        backgroundColor: AppColors.primaryBlue,
        child: Icon(Icons.refresh),
      ),
    );
  }
}
