import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:typeracer/providers/client_state_provider.dart';
import 'package:typeracer/providers/game_state_provider.dart';
import 'package:typeracer/utils/socket_client.dart';

class SocketMethods {
  final _client = SocketClient.instance.socket!;
  bool _isPlaying = false;

  createGame(String nickname) {
    if (nickname.isNotEmpty) {
      _client.emit('create-game', {
        'nickname': nickname,
      });
    }
  }

  joinGame(String gameId, String nickname) {
    if (nickname.isNotEmpty && gameId.isNotEmpty) {
      _client.emit('join-game', {
        'nickname': nickname,
        'gameId': gameId,
      });
    }
  }

  sendUserInput(int index, double wordCount, String gameID) {
    _client.emit('user-input', {
      'currentWordIndex': index,
      'typedWordCount': wordCount,
      'gameID': gameID,
    });
  }

  updateGameListener(BuildContext context) {
    _client.on('update-game', (data) {
      // listen: false because we don't want to rebuild the widget
      Provider.of<GameStateProvider>(context, listen: false).updateGameState(
        id: data['_id'],
        players: data['players'],
        isJoin: data['isJoin'],
        words: data['words'],
        isOver: data['isOver'],
      );

      if (data['_id'].isNotEmpty && !_isPlaying) {
        Navigator.pushNamed(context, '/game-screen');
        _isPlaying = true;
      }
    });
  }

  notCorrectGameListener(BuildContext context) {
    _client.on(
      'not-correct-game',
      (data) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            data,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  startTimer(playerId, gameID) {
    _client.emit(
      'timer',
      {
        'playerId': playerId,
        'gameID': gameID,
      },
    );
  }

  updateTimer(BuildContext context) {
    _client.on('timer', (data) {
      Provider.of<ClientStateProvider>(context, listen: false)
          .setClientState(data);
    });
  }

  updateGame(BuildContext context) {
    _client.on('update-game-state', (data) {
      Provider.of<GameStateProvider>(context, listen: false).updateGameState(
        id: data['_id'],
        players: data['players'],
        isJoin: data['isJoin'],
        words: data['words'],
        isOver: data['isOver'],
      );
    });
  }

  gameFinishedListener() {
    _client.on(
      'done',
      (data) => _client.off('timer'),
    );
  }
}
