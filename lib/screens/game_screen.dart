import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:typetypego/providers/client_state_provider.dart';
import 'package:typetypego/providers/game_state_provider.dart';
import 'package:typetypego/theme/theme_data.dart';
import 'package:typetypego/utils/socket_client.dart';
import 'package:typetypego/utils/socket_methods.dart';
import 'package:typetypego/widgets/sentence.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final SocketMethods _socketMethods = SocketMethods();
  bool showBtn = true;
  var currPlayer = {};
  late String gameId;

  @override
  void initState() {
    super.initState();

    _socketMethods.updateTimer(context);
    _socketMethods.updateGame(context);
    _socketMethods.gameFinishedListener();

    Provider.of<GameStateProvider>(context, listen: false)
        .gameState['players']
        .forEach((player) {
      if (player['socketID'] == SocketClient.instance.socket!.id) {
        currPlayer = player;
      }
    });

    gameId =
        Provider.of<GameStateProvider>(context, listen: false).gameState['id'];
  }

  @override
  void dispose() {
    super.dispose();
    if (gameId.isNotEmpty) {
      _socketMethods.leaveGame(gameId);
    }
  }

  startGame(GameStateProvider game) {
    _socketMethods.startTimer(currPlayer['_id'], game.gameState['id']);
    setState(() {
      showBtn = false;
    });
  }

  void restartGame(GameStateProvider game) {
    _socketMethods.updateTimer(context);
    _socketMethods.restartTimer(game.gameState['id']);
  }

  @override
  Widget build(BuildContext context) {
    final client = Provider.of<ClientStateProvider>(context);
    String message = client.clientState['timer']['msg'].toString();

    return currPlayer.isEmpty
        ? Scaffold(
            body: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Oops! Something went wrong. 😅",
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/');
                    },
                    child: const Text(
                      "Go back to home page",
                      style: TextStyle(
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ))
        : Consumer<GameStateProvider>(
            builder: (context, game, child) {
              gameId = game.gameState['id'];

              return Scaffold(
                body: SafeArea(
                  child: Center(
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 20,
                        ),
                        Text(
                          "typetypego",
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: ThemeApp.green,
                              ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(
                            top: 20,
                          ),
                          child: Chip(
                            label: AnimatedCrossFade(
                              sizeCurve: Curves.easeOutQuad,
                              firstChild: const Text("Waiting for players...",
                                  style: TextStyle(
                                    fontSize: 16,
                                  )),
                              secondChild: Text(message,
                                  style: const TextStyle(
                                    fontSize: 16,
                                  )),
                              crossFadeState: message.isEmpty
                                  ? CrossFadeState.showFirst
                                  : CrossFadeState.showSecond,
                              duration: const Duration(milliseconds: 300),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          client.clientState['timer']['countDown'].toString(),
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 700,
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: game.gameState['players'].length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Chip(
                                      label: Text(
                                        game.gameState['players'][index]
                                                ['nickname']
                                            .toString()
                                            .toLowerCase(),
                                        style: const TextStyle(
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Slider(
                                      value: (game.gameState['players'][index]
                                              ['currentWordIndex'] /
                                          (game.gameState['words'].length)),
                                      onChanged: (val) {},
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        if (game.gameState['isJoin']) ...{
                          ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 700,
                            ),
                            child: TextField(
                              readOnly: true,
                              onTap: () {
                                Clipboard.setData(ClipboardData(
                                  text: game.gameState['id'],
                                )).then((_) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Game Id has been copied to clickboard.',
                                        textAlign: TextAlign.center,
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      elevation: 10,
                                      width: 300,
                                    ),
                                  );
                                });
                              },
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Colors.transparent,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Colors.transparent,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                fillColor: const Color(
                                  0xffF5F5FA,
                                ),
                                hintText: 'Click to Copy Game Code',
                                hintStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          )
                        },
                        if (!game.gameState["isJoin"]) ...{
                          Sentence(
                              words: game.gameState["words"],
                              onRestart: (game) => restartGame(game))
                        },
                        if (currPlayer['isPartyLeader'] && showBtn) ...{
                          const SizedBox(height: 30),
                          ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 700,
                            ),
                            child: Container(
                              alignment: Alignment.centerRight,
                              child: OutlinedButton(
                                onPressed: () => startGame(game),
                                child: const Text(
                                  "START",
                                  style: TextStyle(
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        },
                      ],
                    ),
                  ),
                ),
              );
            },
          );
  }
}
