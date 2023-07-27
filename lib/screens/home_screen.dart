import 'package:flutter/material.dart';
import 'package:typeracer/theme/theme_data.dart';
import 'package:typeracer/widgets/custom_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 700,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('TypeTypeGo',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: ThemeApp.green,
                      )),
              const SizedBox(height: 20),
              Text(
                'Create/Join a room to play!',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                    ),
              ),
              SizedBox(
                height: size.height * 0.05,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomButton(
                    text: 'Create',
                    onTap: () {
                      Navigator.pushNamed(context, '/create-room');
                    },
                    isHome: true,
                  ),
                  const SizedBox(width: 20),
                  CustomButton(
                    text: 'Join',
                    onTap: () => Navigator.pushNamed(context, '/join-room'),
                    isHome: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
