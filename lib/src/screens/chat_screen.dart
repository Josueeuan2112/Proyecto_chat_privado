import 'package:flutter/material.dart';
import 'package:whatsapp_flutter/src/service/api_service.dart';
import 'package:whatsapp_flutter/src/service/socket_service.dart';

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

  List<Map<String, dynamic>> messages = [];
  bool isLoading = true;
  bool isOtherUserTyping = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupSocketListeners();
  }

  // FUNCIÓN PARA CARGAR HISTORIAL DE MENSAJES
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
      // Scroll al último mensaje
      _scrollToBottom();
    }
  }

  // FUNCIÓN PARA CONFIGURAR LOS LISTENERS DE SOCKET
  void _setupSocketListeners() {
    // Escuchar mensajes recibidos
    widget.socketService.onMessageReceived = (message) {
      if (message['sender_id'] == widget.otherUserId) {
        setState(() {
          messages.add(message);
        });
        _scrollToBottom();
      }
    };

    // Escuchar confirmación de mensaje enviado
    widget.socketService.onMessageSent = (message) {
      // Actualizar el último mensaje con el ID de la BD
      if (messages.isNotEmpty &&
          messages.last['content'] == message['content']) {
        setState(() {
          messages.last = message;
        });
      }
    };

    // Escuchar cuando el otro usuario está escribiendo
    widget.socketService.onUserTyping = (data) {
      if (data['userId'] == widget.otherUserId) {
        setState(() {
          isOtherUserTyping = true;
        });
      }
    };

    // Escuchar cuando el otro usuario dejó de escribir
    widget.socketService.onUserStopTyping = (userId) {
      if (userId == widget.otherUserId) {
        setState(() {
          isOtherUserTyping = false;
        });
      }
    };

    // Escuchar errores
    widget.socketService.onError = (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $error')));
    };
  }

  // FUNCIÓN PARA ENVIAR UN MENSAJE
  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) {
      return;
    }

    final content = _messageController.text.trim();
    _messageController.clear();

    // Crear un mensaje temporal para mostrar de inmediato
    setState(() {
      messages.add({
        'id': -1, // ID temporal
        'sender_id': widget.currentUserId,
        'receiver_id': widget.otherUserId,
        'content': content,
        'timestamp': DateTime.now().toIso8601String(),
        'is_read': 0,
      });
    });

    _scrollToBottom();

    // Notificar que dejó de escribir
    widget.socketService.notifyStopTyping(widget.otherUserId);

    // Enviar el mensaje al servidor
    widget.socketService.sendMessage(widget.otherUserId, content);
  }

  // FUNCIÓN PARA SCROLL AUTOMÁTICO AL FINAL
  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        // Scroll al final de la lista
      }
    });
  }

  // FUNCIÓN PARA NOTIFICAR ESCRITURA
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
    widget.socketService.notifyStopTyping(widget.otherUserId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUsername),
            if (isOtherUserTyping)
              Text(
                'escribiendo...',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
          ],
        ),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Column(
        children: [
          // LISTA DE MENSAJES
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : messages.isEmpty
                ? Center(
                    child: Text(
                      'No hay mensajes aún. ¡Sé el primero en escribir!',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isCurrentUser =
                          message['sender_id'] == widget.currentUserId;

                      return Align(
                        alignment: isCurrentUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.symmetric(vertical: 4),
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isCurrentUser
                                ? Colors.blue.shade400
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: isCurrentUser
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                message['content'],
                                style: TextStyle(
                                  color: isCurrentUser
                                      ? Colors.white
                                      : Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                _formatTime(message['timestamp']),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isCurrentUser
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // BARRA DE ENTRADA DE MENSAJES
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onChanged: _onMessageChanged,
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: _sendMessage,
                  backgroundColor: Colors.blue.shade700,
                  child: Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // FUNCIÓN AUXILIAR PARA FORMATEAR LA HORA
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
