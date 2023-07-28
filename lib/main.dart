import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:typetypego/providers/client_state_provider.dart';
import 'package:typetypego/providers/game_state_provider.dart';
import 'package:typetypego/screens/create_screen.dart';
import 'package:typetypego/screens/game_screen.dart';
import 'package:typetypego/screens/home_screen.dart';
import 'package:typetypego/screens/join_screen.dart';
import 'package:typetypego/theme/theme_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => GameStateProvider()),
        ChangeNotifierProvider(create: (ctx) => ClientStateProvider()),
      ],
      child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'typetypego',
          theme: ThemeApp.theme,
          initialRoute: '/',
          routes: {
            '/': (context) => const HomeScreen(),
            '/create-room': (context) => const CreateRoomScreen(),
            '/join-room': (context) => const JoinRoomScreen(),
            '/game-screen': (context) => const GameScreen(),
          }),
    );
  }
}
