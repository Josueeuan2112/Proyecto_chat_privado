import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api_service.dart';

class SocketService {
  static const String baseUrl = 'http://192.168.1.153:3000';
  late IO.Socket socket;
  bool isConnected = false;

  // Callbacks para escuchar eventos
  Function(Map<String, dynamic>)? onMessageReceived;
  Function(Map<String, dynamic>)? onMessageSent;
  Function(Map<String, dynamic>)? onUserTyping;
  Function(int)? onUserStopTyping;
  Function(String)? onError;

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

  // FUNCIÓN PARA DESCONECTARSE
  void disconnect() {
    if (isConnected) {
      socket.disconnect();
      isConnected = false;
      print('❌ Socket desconectado manualmente');
    }
  }
}
