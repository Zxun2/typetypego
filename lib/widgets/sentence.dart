import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:typetypego/models/typing_state.dart';
import 'package:typetypego/providers/game_state_provider.dart';
import 'package:typetypego/theme/theme_data.dart';
import 'package:typetypego/utils/socket_client.dart';
import 'package:typetypego/utils/socket_methods.dart';
import 'package:typetypego/widgets/input_listener.dart';
import 'package:typetypego/widgets/scoreboard.dart';
import 'package:typetypego/widgets/word_generator.dart';

class Sentence extends StatefulWidget {
  final List<dynamic> words;
  final Function onRestart;
  Sentence({Key? key, required this.words, required this.onRestart})
      : super(key: key) {
    WordGenerator.initializeWordList(words);
  }

  @override
  State<Sentence> createState() => _Sentence();
}

class _Sentence extends State<Sentence> with SingleTickerProviderStateMixin {
  late TypingContext typingContext = TypingContext(0, wordListType);
  final SocketMethods _socketMethods = SocketMethods();
  WordListType wordListType = WordListType.top100;
  final FocusNode focusNode = FocusNode();
  int currentWordIndex = 0;

  Timer? cursorResetTimer;
  var currPlayer = {};
  bool isTestEnabled = true;

  static const Duration cursorFadeDuration = Duration(milliseconds: 750);
  late final AnimationController cursorAnimation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  @override
  void initState() {
    super.initState();
    cursorAnimation.repeat(reverse: true);
    _socketMethods.updateGame(context);

    Provider.of<GameStateProvider>(context, listen: false)
        .gameState['players']
        .forEach((player) {
      if (player['socketID'] == SocketClient.instance.socket!.id) {
        currPlayer = player;
      }
    });

    refreshTypingContext();
  }

  @override
  void dispose() {
    cursorAnimation.dispose();
    super.dispose();
  }

  void refreshTypingContext() {
    typingContext = TypingContext(0, wordListType);
    isTestEnabled = true;
  }

  void resetCursor() {
    cursorAnimation.value = 1;
    cursorResetTimer?.cancel();
    cursorResetTimer = Timer(cursorFadeDuration, () {
      cursorAnimation.repeat(reverse: true);
    });
  }

  void restartGame(game) {
    widget.onRestart(game);
    refreshTypingContext();
  }

  @override
  Widget build(BuildContext context) {
    bool isCurrentWordWrong =
        !typingContext.currentWord.startsWith(typingContext.enteredText);
    final game = Provider.of<GameStateProvider>(context);

    return InputListener(
      focusNode: focusNode,
      enabled: !game.gameState['isOver'],
      onSpacePressed: () {
        setState(() {
          bool isEnd = typingContext.onSpacePressed();
          if (currentWordIndex == typingContext.words.length - 1) {
            currentWordIndex = typingContext.currentWordIndex + 1;
          } else {
            currentWordIndex = typingContext.currentWordIndex;
          }
          if (isEnd) {
            isTestEnabled = false;
          }
          resetCursor();
        });

        _socketMethods.sendUserInput(
          currentWordIndex,
          typingContext.getTypedWordCount(),
          game.gameState["id"],
        );
      },
      onCtrlBackspacePressed: () {
        if (typingContext.deleteFullWord()) {
          _socketMethods.sendUserInput(
            typingContext.currentWordIndex,
            typingContext.getTypedWordCount(),
            game.gameState["id"],
          );

          setState(() {
            resetCursor();
          });
        }
      },
      onBackspacePressed: () {
        if (typingContext.deleteCharacter()) {
          _socketMethods.sendUserInput(
            typingContext.currentWordIndex,
            typingContext.getTypedWordCount(),
            game.gameState["id"],
          );

          setState(() {
            resetCursor();
          });
        }
      },
      onCharacterInput: (String character) {
        setState(() {
          typingContext.onCharacterEntered(character);
          resetCursor();
        });
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: FittedBox(
          fit: BoxFit.contain,
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Stack(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        switchInCurve: const Interval(0.0, 0.5),
                        switchOutCurve: const Interval(0.5, 1.0),
                        layoutBuilder: (currentChild, previousChildren) {
                          return Stack(
                            alignment: Alignment.topLeft,
                            children: [
                              ...previousChildren,
                              if (currentChild != null) currentChild,
                            ],
                          );
                        },
                        child: Column(
                          key: const ValueKey(0),
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (typingContext.currentLineIndex > 0) ...{
                              buildLine(typingContext.currentLineIndex - 1),
                            },
                            buildCurrentLine(isCurrentWordWrong),
                            buildLineAtOffset(1),
                            if (typingContext.currentLineIndex == 0)
                              buildLineAtOffset(2),
                          ],
                        ),
                      ),
                      Positioned.fill(
                        child: AnimatedOpacity(
                          opacity: !game.gameState['isOver'] ? 0 : 1,
                          duration: const Duration(milliseconds: 300),
                          child: Container(
                            height: 300,
                            color: Theme.of(context).scaffoldBackgroundColor,
                            child: const Align(
                              alignment: Alignment.centerLeft,
                              child: Scoreboard(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (game.gameState["isOver"]) ...{
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.end,
                      children: [
                        if (currPlayer['isPartyLeader'])
                          OutlinedButton.icon(
                            onPressed: () => restartGame(game),
                            icon: const Icon(Icons.restart_alt_rounded),
                            label: const Text(
                              "Restart",
                              style: TextStyle(
                                fontSize: 15,
                              ),
                            ),
                          ),
                        // OutlinedButton.icon(
                        //   onPressed: () {
                        //     Navigator.pushtNamed(context, '/');
                        //   },
                        //   icon: const Icon(Icons.home),
                        //   label: const Text(
                        //     "Go back to Home",
                        //     style: TextStyle(
                        //       fontSize: 15,
                        //     ),
                        //   ),
                        // ),
                      ],
                    )
                  }
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildLineAtOffset(int offset) {
    final nextLineStart =
        typingContext.getLineStart(typingContext.currentLineIndex + offset);

    return nextLineStart < 0
        ? const SizedBox()
        : Padding(
            padding: const EdgeInsetsDirectional.only(start: 6, end: 20),
            child: Text(
              typingContext.getLine(nextLineStart),
              textAlign: TextAlign.justify,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: Theme.of(context).hintColor),
            ),
          );
  }

  Widget buildLine(int lineIndex) {
    List<TypedWord> typedWords = typingContext.getTypedLine(lineIndex);
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 6, end: 20),
      child: RichText(
        text: TextSpan(
          children: [
            for (TypedWord typedWord in typedWords) ...{
              TextSpan(
                text: typedWord.value,
                style: TextStyle(
                  color: typedWord.isCorrect ? ThemeApp.green : ThemeApp.red,
                ),
              ),
              if (typedWord.trailingHint != null) ...{
                TextSpan(
                  text: typedWord.trailingHint,
                  style: TextStyle(
                    color: Colors.red[200],
                  ),
                ),
              },
              if (typedWord != typedWords.last)
                TextSpan(
                  text: ' ',
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                  ),
                ),
            },
          ],
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }

  Widget buildCurrentLine(bool isCurrentWordWrong) {
    final remainingWords = typingContext.getRemainingWords();

    return Stack(
      alignment: Alignment.centerLeft,
      children: <Widget>[
        IntrinsicHeight(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSize(
                alignment: Alignment.centerRight,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: RichText(
                  text: TextSpan(
                    children: [
                      for (TypedWord typedWord in typingContext
                          .getTypedLine(typingContext.currentLineIndex)) ...{
                        TextSpan(
                          text: typedWord.value,
                        ),
                        if (typedWord.trailingHint != null) ...{
                          TextSpan(
                            text: typedWord.trailingHint,
                          ),
                        },
                        const TextSpan(
                          text: ' ',
                        ),
                      },
                      TextSpan(
                        text: typingContext.enteredText,
                      ),
                    ],
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(color: Colors.transparent),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: cursorAnimation
                    .drive(CurveTween(curve: Curves.easeInOutQuint)),
                builder: (context, child) {
                  return Opacity(
                    opacity: cursorAnimation.value,
                    child: child,
                  );
                },
                child: Container(
                  width: 4,
                  color: ThemeApp.yellow,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 6, end: 20),
          child: RichText(
            text: TextSpan(
              children: [
                for (TypedWord typedWord in typingContext
                    .getTypedLine(typingContext.currentLineIndex)) ...{
                  TextSpan(
                    text: typedWord.value,
                    style: TextStyle(
                      color:
                          typedWord.isCorrect ? ThemeApp.green : ThemeApp.red,
                    ),
                  ),
                  if (typedWord.trailingHint != null) ...{
                    TextSpan(
                      text: typedWord.trailingHint,
                      style: TextStyle(
                        color: Colors.red[200],
                      ),
                    ),
                  },
                  TextSpan(
                    text: ' ',
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                },
                TextSpan(
                  text: typingContext.enteredText,
                  style: TextStyle(
                    color: isCurrentWordWrong ? ThemeApp.red : ThemeApp.green,
                  ),
                ),
                if (remainingWords.isNotEmpty)
                  TextSpan(
                    text: remainingWords.first.substring(
                      min(
                        typingContext.enteredText.length,
                        remainingWords.first.length,
                      ),
                    ),
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                if (remainingWords.length > 1)
                  TextSpan(
                    text: ' ${remainingWords.skip(1).join(' ')}',
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
              ],
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        ),
      ],
    );
  }
}
