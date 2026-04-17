import 'package:flutter/material.dart';
import 'package:whatsapp_flutter/src/providers/user_provider.dart';
import 'package:whatsapp_flutter/src/screens/auth_screen.dart';
import 'package:whatsapp_flutter/src/screens/chats_list_screen.dart';
import 'package:whatsapp_flutter/src/screens/profile_screen.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => UserProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WhatsApp Clone',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: AuthScreen(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/auth': (context) => AuthScreen(),
        '/chats': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          return ChatsListScreen(
            userId: args?['userId'] ?? 0,
            username: args?['username'] ?? '',
            token: args?['token'] ?? '',
          );
        },
        '/profile': (context) => ProfileScreen(
          userId: 1,
          username: 'Usuario',
          email: 'email@example.com',
        ),
      },
    );
  }
}
