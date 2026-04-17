import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:whatsapp_flutter/src/providers/notification_provide.dart';
import 'package:whatsapp_flutter/src/screens/profile_screen.dart';
import 'package:whatsapp_flutter/src/service/api_service.dart';
import 'package:whatsapp_flutter/src/service/socket_service.dart';
import 'package:whatsapp_flutter/src/constants/app_colors.dart';
import 'package:whatsapp_flutter/src/constants/app_text_styles.dart';
import 'package:whatsapp_flutter/src/widgets/user_avatar.dart';
import 'package:whatsapp_flutter/src/widgets/typing_indicator.dart';

class ChatScreen extends StatefulWidget {
  final int currentUserId;
  final String currentUsername;
  final int otherUserId;
  final String otherUsername;
  final SocketService socketService;

  const ChatScreen({
    required this.currentUserId,
    required this.currentUsername,
    required this.otherUserId,
    required this.otherUsername,
    required this.socketService,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> messages = [];
  bool isLoading = true;
  bool isOtherUserTyping = false;
  bool _isComposing = false;
  bool _hasMarkedAsRead = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupSocketListeners();
    _messageController.addListener(() {
      setState(() {
        _isComposing = _messageController.text.isNotEmpty;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markMessagesAsRead();
    });
  }

  // MARCAR MENSAJES COMO LEÍDOS DE FORMA SEGURA
  Future<void> _markMessagesAsRead() async {
    // Evitar marcar dos veces
    if (_hasMarkedAsRead || !mounted) return;

    _hasMarkedAsRead = true;

    try {
      await Future.delayed(Duration(milliseconds: 300));
      if (!mounted) return;

      print('📖 Marcando mensajes de ${widget.otherUsername} como leídos...');
      await context.read<NotificationProvider>().markAsRead(widget.otherUserId);

      print('✅ Mensajes marcados como leídos');
    } catch (e) {
      print('❌ Error marcando como leído: $e');
    }
  }

  Future<void> _loadMessages() async {
    setState(() {
      isLoading = true;
    });

    final messagesList = await _apiService.getMessages(widget.otherUserId);

    if (mounted) {
      setState(() {
        messages = messagesList;
        isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _setupSocketListeners() {
    widget.socketService.onMessageReceived = (message) {
      if (message['sender_id'] == widget.otherUserId && mounted) {
        setState(() {
          messages.add(message);
        });
        _scrollToBottom();
      }
    };

    widget.socketService.onMessageSent = (message) {
      if (mounted &&
          messages.isNotEmpty &&
          messages.last['content'] == message['content']) {
        setState(() {
          messages.last = message;
        });
      }
    };

    widget.socketService.onUserTyping = (data) {
      if (data['userId'] == widget.otherUserId && mounted) {
        setState(() {
          isOtherUserTyping = true;
        }); //lll
      }
    };

    widget.socketService.onUserStopTyping = (userId) {
      if (userId == widget.otherUserId && mounted) {
        setState(() {
          isOtherUserTyping = false;
        });
      }
    };

    widget.socketService.onError = (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $error')));
      }
    };
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) {
      return;
    }

    final content = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      messages.add({
        'id': -1,
        'sender_id': widget.currentUserId,
        'receiver_id': widget.otherUserId,
        'content': content,
        'timestamp': DateTime.now().toIso8601String(),
        'is_read': 0,
      });
    });

    _scrollToBottom();

    widget.socketService.notifyStopTyping(widget.otherUserId);
    widget.socketService.sendMessage(widget.otherUserId, content);
  }

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

  void _onMessageChanged(String value) {
    if (value.isNotEmpty) {
      widget.socketService.notifyTyping(widget.otherUserId);
    } else {
      widget.socketService.notifyStopTyping(widget.otherUserId);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    widget.socketService.notifyStopTyping(widget.otherUserId);

    // Limpiar callbacks para evitar memory leaks
    widget.socketService.onMessageReceived = null;
    widget.socketService.onMessageSent = null;
    widget.socketService.onUserTyping = null;
    widget.socketService.onUserStopTyping = null;
    widget.socketService.onError = null;

    super.dispose();
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
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(
                  userId: widget.otherUserId,
                  username: widget.otherUsername,
                  email: 'usuario@example.com', // Por ahora dejamos así
                  isOwnProfile: false,
                  status: isOtherUserTyping ? 'online' : 'offline',
                ),
              ),
            ).then((_) {
              _loadMessages(); //refrecar perfil al volver del perfil
            });
          },
          child: Row(
            children: [
              UserAvatar(username: widget.otherUsername, size: 40),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.otherUsername,
                      style: AppTextStyles.subtitle.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      isOtherUserTyping ? 'escribiendo...' : 'en línea',
                      style: AppTextStyles.caption.copyWith(
                        color: isOtherUserTyping
                            ? AppColors.primaryBlue
                            : Colors.green,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
                          Icons.chat_bubble_outline,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'No hay mensajes aún',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '¡Sé el primero en escribir!',
                          style: AppTextStyles.caption,
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

                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Align(
                          alignment: isCurrentUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
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
                        ),
                      );
                    },
                  ),
          ),

          // INDICADOR DE ESCRITURA
          if (isOtherUserTyping)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TypingIndicator(username: widget.otherUsername),
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
              child: Row(
                children: [
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
                          prefixIcon: Icon(
                            Icons.add_circle_outline,
                            color: AppColors.primaryBlue,
                          ),
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
                        onTap: _isComposing ? _sendMessage : null,
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
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (e) {
      return '';
    }
  }
}
