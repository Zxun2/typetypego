import 'package:flutter/material.dart';
import 'package:typetypego/models/game_state.dart';

class GameStateProvider extends ChangeNotifier {
  GameState _gameState = GameState(
    id: '',
    players: [],
    isJoin: true,
    words: [],
    isOver: false,
  );

  Map<String, dynamic> get gameState => _gameState.toJson();

  void updateGameState({
    required String id,
    required List players,
    required bool isJoin,
    required List words,
    required bool isOver,
  }) {
    _gameState = GameState(
      id: id,
      players: players,
      isJoin: isJoin,
      words: words,
      isOver: isOver,
    );
    notifyListeners();
  }

  void resetState() {
    _gameState = GameState(
      id: '',
      players: [],
      isJoin: true,
      words: [],
      isOver: false,
    );
    notifyListeners();
  }
}
