import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:typeracer/providers/client_state_provider.dart';
import 'package:typeracer/providers/game_state_provider.dart';
import 'package:typeracer/screens/create_screen.dart';
import 'package:typeracer/screens/game_screen.dart';
import 'package:typeracer/screens/home_screen.dart';
import 'package:typeracer/screens/join_screen.dart';
import 'package:typeracer/theme/theme_data.dart';

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
          title: 'Typeracer',
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
