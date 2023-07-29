import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:typetypego/providers/game_state_provider.dart';
import 'package:typetypego/utils/socket_methods.dart';
import 'package:typetypego/widgets/custom_button.dart';
import 'package:typetypego/widgets/custom_textfield.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final TextEditingController nameController = TextEditingController();
  final _socketMethods = SocketMethods();

  @override
  void initState() {
    super.initState();
    _socketMethods.updateGameListener(context);
    _socketMethods.notCorrectGameListener(context);
  }

  @override
  void dispose() {
    super.dispose();
    nameController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Center(
          child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 700,
        ),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: size.width * 0.1),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Create Room',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                    ),
              ),
              SizedBox(
                height: size.height * 0.05,
              ),
              CustomTextField(
                  controller: nameController, hintText: "Enter your nickname"),
              SizedBox(
                height: size.height * 0.03,
              ),
              CustomButton(
                  text: "Create",
                  onTap: () {
                    Provider.of<GameStateProvider>(context, listen: false)
                        .resetState();
                    _socketMethods.createGame(nameController.text);
                  })
            ],
          ),
        ),
      )),
    );
  }
}
