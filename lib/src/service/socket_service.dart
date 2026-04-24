import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api_service.dart';

class SocketService {
  static const String baseUrl = 'http://19.2.168.1.153:3000';
  late IO.Socket socket;
  bool isConnected = false;

  // Callbacks para escuchar eventos
  Function(Map<String, dynamic>)? onMessageReceived;
  Function(Map<String, dynamic>)? onMessageSent;
  Function(Map<String, dynamic>)? onUserTyping;
  Function(int)? onUserStopTyping;
  Function(String)? onError;

  // Callbacks para grupos
  Function? onGroupMessageReceived;
  Function? onGroupMessageSent;
  Function? onUserJoinedGroup;
  Function? onUserLeftGroup;
  Function? onUserTypingInGroup;
  Function? onUserStopTypingInGroup;

  // FUNCIÓN PARA CONECTARSE AL SERVIDOR
  Future<void> connect(String token) async {
    if (isConnected) {
      print('⚠️ Socket ya está conectado');
      return;
    }

    try {
      socket = IO.io(
        baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .build(),
      );

      // ==========================================
      // LISTENERS PARA CHATS GRUPALES
      // ==========================================

      // Cuando un usuario se une al grupo
      socket.on('user_joined_group', (data) {
        if (onUserJoinedGroup != null) {
          try {
            onUserJoinedGroup!(data);
            print('👥 Usuario se unió al grupo: ${data['userId']}');
          } catch (e) {
            print('⚠️ Error en onUserJoinedGroup: $e');
          }
        }
      });

      // Cuando un usuario sale del grupo
      socket.on('user_left_group', (data) {
        if (onUserLeftGroup != null) {
          try {
            onUserLeftGroup!(data);
            print('👋 Usuario salió del grupo: ${data['userId']}');
          } catch (e) {
            print('⚠️ Error en onUserLeftGroup: $e');
          }
        }
      });

      // Cuando alguien está escribiendo en el grupo
      socket.on('user_typing_group', (data) {
        if (onUserTypingInGroup != null) {
          try {
            final userId = int.tryParse(data['userId'].toString());
            if (userId != null) {
              onUserTypingInGroup!(data);
              print('✏️ Usuario escribiendo en grupo: ${data['username']}');
            }
          } catch (e) {
            print('⚠️ Error en onUserTypingInGroup: $e');
          }
        }
      });

      // Cuando alguien deja de escribir en el grupo
      socket.on('user_stop_typing_group', (data) {
        if (onUserStopTypingInGroup != null) {
          try {
            final userId = int.tryParse(data['userId'].toString());
            if (userId != null) {
              onUserStopTypingInGroup!(data);
              print('⏹️ Usuario dejó de escribir');
            }
          } catch (e) {
            print('⚠️ Error en onUserStopTypingInGroup: $e');
          }
        }
      });

      // Conectar
      socket.connect();

      // Cuando se conecta
      socket.onConnect((_) {
        print('✅ Socket conectado');
        isConnected = true;
        // Autenticarse con el servidor
        socket.emit('authenticate', token);
      });

      // Cuando se autentica correctamente
      socket.on('authenticated', (data) {
        print('✅ Autenticado en Socket: ${data['username']}');
      });

      // Cuando se recibe un mensaje
      socket.on('receive_message', (data) {
        print('📨 Mensaje recibido: ${data['content']}');
        if (onMessageReceived != null) {
          onMessageReceived!(Map<String, dynamic>.from(data));
        }
      });

      // Cuando el servidor confirma que el mensaje fue enviado
      socket.on('message_sent', (data) {
        print('✅ Mensaje confirmado enviado');
        if (onMessageSent != null) {
          onMessageSent!(data['message']);
        }
      });

      // Cuando alguien está escribiendo
      socket.on('user_typing', (data) {
        if (onUserTyping != null) {
          onUserTyping!(Map<String, dynamic>.from(data));
        }
      });

      // Cuando alguien dejó de escribir
      socket.on('user_stop_typing', (data) {
        if (onUserStopTyping != null) {
          onUserStopTyping!(data['userId']);
        }
      });

      // Cuando hay error
      socket.on('error', (data) {
        print('❌ Error en Socket: $data');
        if (onError != null) {
          onError!(data['message'] ?? 'Error desconocido');
        }
      });

      // Cuando se desconecta
      socket.onDisconnect((_) {
        print('❌ Socket desconectado');
        isConnected = false;
      });

      // Conectar
      socket.connect();
    } catch (e) {
      print('❌ Error conectando socket: $e');
      if (onError != null) {
        onError!('Error de conexión: $e');
      }
    }
  }

  // FUNCIÓN PARA ENVIAR UN MENSAJE
  void sendMessage(int receiverId, String content) {
    if (!isConnected) {
      print('❌ Socket no está conectado');
      return;
    }

    socket.emit('send_message', {'receiverId': receiverId, 'content': content});

    print('📤 Mensaje enviado a usuario $receiverId');
  }

  // ENVIAR IMAGEN
  void sendImage(int receiverId, String imageUrl) {
    if (!isConnected) {
      print('❌ Socket no está conectado');
      return;
    }

    socket.emit('send_image', {'receiverId': receiverId, 'imageUrl': imageUrl});

    print('🖼️ Imagen enviada a usuario $receiverId');
  }

  // FUNCIÓN PARA NOTIFICAR QUE ESTÁ ESCRIBIENDO
  void notifyTyping(int receiverId) {
    if (!isConnected) return;
    socket.emit('typing', {'receiverId': receiverId});
  }

  // FUNCIÓN PARA NOTIFICAR QUE DEJÓ DE ESCRIBIR
  void notifyStopTyping(int receiverId) {
    if (!isConnected) return;
    socket.emit('stop_typing', {'receiverId': receiverId});
  }

  void jointGroup(int groupId, int userId) {
    if (!isConnected) {
      print('❌ Socket no está conectado');
      return;
    }

    socket.emit('join_group', {'groupId': groupId, 'userId': userId});

    print('Se unió al grupo $groupId');
  }

  //Envio de mensajes al grupo
  void sendGroupMessage(int groupId, String content) {
    if (!isConnected) {
      print('❌ Socket no está conectado');
      return;
    }

    socket.emit('send_group_message', {'groupId': groupId, 'content': content});

    print('Mensaje enviado al grupo $groupId');
  }

  //enviar imagen al grupo
  void sendGroupImage(int groupId, String imageUrl) {
    if (!isConnected) {
      print('❌ Socket no está conectado');
      return;
    }

    socket.emit('send_group_image', {'groupId': groupId, 'imageUrl': imageUrl});

    print('🖼️ Imagen de grupo enviada al grupo $groupId');
  }

  // Notificar que está escribiendo en el grupo
  void notifyGroupTyping(int groupId, String username) {
    if (!isConnected) return;

    socket.emit('group_typing', {'groupId': groupId, 'username': username});

    print('✏️ Notificando escritura en grupo $groupId');
  }

  // Notificar que dejó de escribir en el grupo
  void notifyGroupStopTyping(int groupId) {
    if (!isConnected) return;

    socket.emit('group_stop_typing', {'groupId': groupId});

    print('⏹️ Dejó de escribir en grupo $groupId');
  }

  // SALIR DE LA SALA DE GRUPO
  void leaveGroup(int groupId, int userId) {
    if (!isConnected) {
      print('❌ Socket no está conectado');
      return;
    }

    socket.emit('leave_group', {'groupId': groupId, 'userId': userId});

    print('👋 Salió del grupo $groupId');
  }

  // FUNCIÓN PARA DESCONECTARSE
  void disconnect() {
    if (isConnected) {
      socket.disconnect();
      isConnected = false;
      print('❌ Socket desconectado manualmente');
    }
  }
}
