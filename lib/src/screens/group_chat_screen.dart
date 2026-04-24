import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:whatsapp_flutter/src/screens/profile_screen.dart';
import 'package:whatsapp_flutter/src/service/api_service.dart';
import 'package:whatsapp_flutter/src/service/image_upload_service.dart';
import 'package:whatsapp_flutter/src/service/socket_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../providers/user_provider.dart';
import '../widgets/user_avatar.dart';

class GroupChatScreen extends StatefulWidget {
  final int groupId;
  final String groupName;
  final int currentUserId;
  final SocketService socketService;

  const GroupChatScreen({
    required this.groupId,
    required this.groupName,
    required this.currentUserId,
    required this.socketService,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final ApiService _apiService = ApiService();
  final ImageUploadService _imageUploadService = ImageUploadService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> messages = [];
  List<Map<String, dynamic>> members = [];
  bool isLoading = true;
  bool _isComposing = false;
  bool _isUploadingImage = false;
  bool _hasJoinedGroup = false;
  Set<int> typingUsers = {};

  @override
  void initState() {
    super.initState();
    _loadGroupData();
    _setupSocketListeners();
    _messageController.addListener(() {
      setState(() {
        _isComposing = _messageController.text.isNotEmpty;
      });
    });

    // Unirse a la sala del grupo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _joinGroup();
    });
  }

  // UNIRSE AL GRUPO
  void _joinGroup() {
    widget.socketService.jointGroup(widget.groupId, widget.currentUserId);
    setState(() {
      _hasJoinedGroup = true;
    });
  }

  // CARGAR DATOS DEL GRUPO
  Future<void> _loadGroupData() async {
    try {
      // Cargar mensajes
      final msgs = await _apiService.getGroupMessages(widget.groupId);

      // Cargar miembros
      final mbs = await _apiService.getGroupMembers(widget.groupId);

      if (mounted) {
        setState(() {
          messages = msgs;
          members = mbs;
          isLoading = false;
        });
      }

      _scrollToBottom();
    } catch (e) {
      print('❌ Error cargando datos: $e');
    }
  }

  // CONFIGURAR LISTENERS DE SOCKET
  void _setupSocketListeners() {
    widget.socketService.onMessageReceived = (message) {
      if (message['group_id'] == widget.groupId && mounted) {
        setState(() {
          messages.add(message);
        });
        _scrollToBottom();
      }
    };

    widget.socketService.onUserTypingInGroup = (data) {
      if (data['groupId'] == widget.groupId && mounted) {
        setState(() {
          typingUsers.add(data['userId']);
        });
      }
    };

    widget.socketService.onUserStopTypingInGroup = (data) {
      if (data['groupId'] == widget.groupId && mounted) {
        setState(() {
          typingUsers.remove(data['userId']);
        });
      }
    };

    widget.socketService.onUserJoinedGroup = (data) {
      if (data['groupId'] == widget.groupId && mounted) {
        _loadGroupData();
      }
    };

    widget.socketService.onUserLeftGroup = (data) {
      if (data['groupId'] == widget.groupId && mounted) {
        _loadGroupData();
      }
    };
  }

  // ENVIAR MENSAJE DE TEXTO
  void _sendMessage() {
    if (_messageController.text.trim().isEmpty || !_hasJoinedGroup) {
      return;
    }

    final content = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      messages.add({
        'id': -1,
        'sender_id': widget.currentUserId,
        'group_id': widget.groupId,
        'content': content,
        'message_type': 'text',
        'timestamp': DateTime.now().toIso8601String(),
        'is_read': 0,
      });
    });

    _scrollToBottom();
    widget.socketService.notifyGroupStopTyping(widget.groupId);
    widget.socketService.sendGroupMessage(widget.groupId, content);

    print('💬 Mensaje enviado al grupo ${widget.groupId}');
  }

  // ENVIAR IMAGEN
  Future<void> _sendImage({required bool fromCamera}) async {
    setState(() {
      _isUploadingImage = true;
    });

    try {
      final imageUrl = await _imageUploadService.selectAndUploadImage(
        fromCamera: fromCamera,
      );

      if (imageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir imagen'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (mounted) {
        setState(() {
          messages.add({
            'id': -1,
            'sender_id': widget.currentUserId,
            'group_id': widget.groupId,
            'content': imageUrl,
            'message_type': 'image',
            'timestamp': DateTime.now().toIso8601String(),
            'is_read': 0,
          });
        });
      }

      _scrollToBottom();
      widget.socketService.sendGroupImage(widget.groupId, imageUrl);

      print('🖼️ Imagen enviada al grupo');
    } catch (e) {
      print('❌ Error enviando imagen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  // NOTIFICAR ESCRITURA
  void _onMessageChanged(String value) {
    if (value.isNotEmpty && !typingUsers.contains(widget.currentUserId)) {
      widget.socketService.notifyGroupTyping(
        widget.groupId,
        context.read<UserProvider>().username ?? 'Usuario',
      );
    } else if (value.isEmpty) {
      widget.socketService.notifyGroupStopTyping(widget.groupId);
    }
  }

  // SCROLL AL FINAL
  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    widget.socketService.leaveGroup(widget.groupId, widget.currentUserId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.groupName, style: AppTextStyles.titleMedium),
            Text('${members.length} miembros', style: AppTextStyles.caption),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.people, color: AppColors.primaryBlue),
            onPressed: _showMembersModal,
            tooltip: 'Ver miembros',
          ),
        ],
      ),
      body: Column(
        children: [
          // LISTA DE MENSAJES
          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(AppColors.primaryBlue),
                    ),
                  )
                : messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No hay mensajes aún',
                          style: AppTextStyles.titleMedium,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isCurrentUser =
                          message['sender_id'] == widget.currentUserId;
                      final senderName = message['username'] ?? 'Usuario';

                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Align(
                          alignment: isCurrentUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: isCurrentUser
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              // Nombre del remitente (solo en grupos)
                              if (!isCurrentUser)
                                Padding(
                                  padding: EdgeInsets.only(left: 12, bottom: 4),
                                  child: Text(
                                    senderName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              // Mensaje
                              Container(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.75,
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isCurrentUser
                                      ? AppColors.primaryBlue
                                      : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                    bottomLeft: Radius.circular(
                                      isCurrentUser ? 20 : 0,
                                    ),
                                    bottomRight: Radius.circular(
                                      isCurrentUser ? 0 : 20,
                                    ),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: isCurrentUser
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Si es imagen
                                    if (message['message_type'] == 'image')
                                      Container(
                                        width: 200,
                                        height: 200,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.2,
                                              ),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Image.network(
                                            'http://192.168.1.153:3000${message['content']}',
                                            fit: BoxFit.cover,
                                            loadingBuilder:
                                                (
                                                  context,
                                                  child,
                                                  loadingProgress,
                                                ) {
                                                  if (loadingProgress == null)
                                                    return child;
                                                  return Center(
                                                    child: CircularProgressIndicator(
                                                      valueColor:
                                                          AlwaysStoppedAnimation(
                                                            AppColors
                                                                .primaryBlue,
                                                          ),
                                                    ),
                                                  );
                                                },
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Container(
                                                    color: Colors.grey.shade300,
                                                    child: Icon(
                                                      Icons.broken_image,
                                                      color: Colors.grey,
                                                    ),
                                                  );
                                                },
                                          ),
                                        ),
                                      )
                                    // Si es texto
                                    else
                                      Text(
                                        message['content'],
                                        style: TextStyle(
                                          color: isCurrentUser
                                              ? Colors.white
                                              : AppColors.textDark,
                                          fontSize: 15,
                                          height: 1.4,
                                        ),
                                      ),
                                    SizedBox(height: 6),
                                    Text(
                                      _formatTime(message['timestamp']),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isCurrentUser
                                            ? Colors.white.withOpacity(0.7)
                                            : Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // INDICADOR DE ESCRITURA
          if (typingUsers.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Escribiendo...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          // BARRA DE ENTRADA
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isUploadingImage)
                    Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: LinearProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(
                          AppColors.primaryBlue,
                        ),
                        minHeight: 3,
                      ),
                    ),
                  Row(
                    children: [
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.add_circle_outline,
                          color: AppColors.primaryBlue,
                          size: 28,
                        ),
                        itemBuilder: (BuildContext context) => [
                          PopupMenuItem<String>(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.photo_library,
                                  color: AppColors.primaryBlue,
                                ),
                                SizedBox(width: 12),
                                Text('Galería'),
                              ],
                            ),
                            value: 'gallery',
                          ),
                          PopupMenuItem<String>(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.camera_alt,
                                  color: AppColors.primaryBlue,
                                ),
                                SizedBox(width: 12),
                                Text('Cámara'),
                              ],
                            ),
                            value: 'camera',
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'gallery') {
                            _sendImage(fromCamera: false);
                          } else if (value == 'camera') {
                            _sendImage(fromCamera: true);
                          }
                        },
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.lightGrey,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _messageController,
                            onChanged: _onMessageChanged,
                            maxLines: null,
                            decoration: InputDecoration(
                              hintText: 'Escribe un mensaje...',
                              hintStyle: TextStyle(color: Colors.grey.shade500),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.buttonGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.successGreen.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isComposing && !_isUploadingImage
                                ? _sendMessage
                                : null,
                            borderRadius: BorderRadius.circular(30),
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // MOSTRAR MODAL DE MIEMBROS
  void _showMembersModal() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Miembros (${members.length})',
              style: AppTextStyles.titleMedium,
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  final memberId = member['id'];
                  final username = member['username'];
                  final email = member['email'];
                  final isCurrentUser = memberId == widget.currentUserId;

                  return GestureDetector(
                    onTap: () {
                      if (!isCurrentUser) {
                        // Navegar al perfil del usuario
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(
                              userId: memberId,
                              username: username,
                              email: email,
                              isOwnProfile: false,
                              status: 'online',
                              socketService: widget.socketService,
                            ),
                          ),
                        );
                      }
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isCurrentUser
                              ? AppColors.primaryBlue.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.all(8),
                        child: Row(
                          children: [
                            UserAvatar(username: username, size: 40),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        username,
                                        style: AppTextStyles.titleMedium,
                                      ),
                                      if (isCurrentUser)
                                        Padding(
                                          padding: EdgeInsets.only(left: 8),
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryBlue,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Tú',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  Text(email, style: AppTextStyles.caption),
                                ],
                              ),
                            ),
                            if (!isCurrentUser)
                              Icon(
                                Icons.chevron_right,
                                color: AppColors.primaryBlue,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FORMATEAR TIEMPO
  String _formatTime(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dt);

      if (difference.inSeconds < 60) {
        return 'Ahora';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h';
      } else {
        return '${dt.day}/${dt.month}';
      }
    } catch (e) {
      return '';
    }
  }
}
