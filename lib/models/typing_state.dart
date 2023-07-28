import 'dart:math';

import 'package:typetypego/widgets/word_generator.dart';

class TypedWord {
  const TypedWord.correct(this.value)
      : trailingHint = null,
        isCorrect = true,
        displayedLength = value.length;
  const TypedWord.incorrect(this.value, this.trailingHint)
      : isCorrect = false,
        displayedLength = value.length + (trailingHint?.length ?? 0);

  final String value;
  final String? trailingHint;
  final bool isCorrect;
  final int displayedLength;
}

class TypingContext {
  int _currentLineIndex = 0;
  int _currentWordIndex = 0;

  String _enteredText = '';
  final List<String> words = [];
  final Map<int, String> misspelledWords = {};

  TypingContext(this.seed, WordListType wordListType)
      : wordGenerator = WordGenerator(seed, wordListType) {
    for (String word in WordGenerator.words) {
      addWord(word);
    }
  }

  final WordGenerator wordGenerator;

  final List<int> lineStarts = [];
  static const int maxLineLength = 50;
  static const int maxWordLength = 20;
  static const int wordBufferLength = maxLineLength;
  final int seed;

  int get currentLineIndex => _currentLineIndex;
  int get currentWordIndex => _currentWordIndex;

  String get enteredText => _enteredText;

  set enteredText(String value) {
    bool previouslyOvershot = _enteredText.length > currentWord.length;
    bool currentlyOvershot = value.length > currentWord.length;

    if (value.length > maxWordLength) {
      return; // don't append anymore to the screen
    } else {
      int typedLength = getTypedLine(currentLineIndex)
              .map((w) => w.displayedLength)
              .fold<int>(0, (a, b) => a + b + 1) +
          value.length;
      if (typedLength > maxLineLength) {
        return;
      }
    }
    _enteredText = value;
    if (previouslyOvershot || currentlyOvershot) {
      // If the user has entered a word that is one character off,
      // recalculate remaining words
      lineStarts.removeRange(currentLineIndex + 1, lineStarts.length);
    }
  }

  set currentWordIndex(int value) {
    _currentWordIndex = value;
    if (value >= words.length) {
      return;
    }
    int wordCount = _getWordsInLine(currentLineStart);

    if (currentWordIndex >= currentLineStart + wordCount) {
      _currentLineIndex++;
    } else if (currentWordIndex < currentLineStart) {
      _currentLineIndex--;
    }
  }

  String get currentWord => words[currentWordIndex];

  List<String> getRemainingWords() {
    int currentLineStart = getLineStart(currentLineIndex);

    return words
        .skip(currentLineStart)
        .take(_getWordsInLine(currentLineStart))
        .skip(currentWordIndex - currentLineStart)
        .toList();
  }

  String getLine(int lineStart) {
    return words.skip(lineStart).take(_getWordsInLine(lineStart)).join(' ');
  }

  int get currentLineStart => getLineStart(currentLineIndex);

  int _getWordsInLine(int lineStart) {
    int charCount = -1;
    int wordCount = 0;
    while (charCount <= maxLineLength) {
      if (lineStart >= words.length) {
        break;
      }
      int wordIndex = lineStart + wordCount;
      if (wordIndex == currentWordIndex) {
        // either the correct word, or wtv the user has typed
        if (charCount + max(currentWord.length, enteredText.length) + 1 <=
            maxLineLength) {
          charCount += max(currentWord.length, enteredText.length) + 1;
        } else {
          break;
        }
      } else {
        // retrieve the typed word at pos i and add 1 for a space
        int count = getTypedWord(wordIndex).displayedLength;
        if (count > 0 && charCount + count + 1 <= maxLineLength) {
          charCount += count + 1;
        } else {
          break;
        }
      }
      wordCount++;
    }

    return wordCount;
  }

  String? popWord() {
    if (currentWordIndex > 0) {
      String poppedWord = getTypedWord(currentWordIndex - 1).value;
      currentWordIndex--;
      return poppedWord;
    }
    return null;
  }

  TypedWord getTypedWord(int wordIndex) {
    if (wordIndex >= words.length) {
      return const TypedWord.correct('');
    }
    String correctWord = words[wordIndex];
    String? misspelledWord = misspelledWords[wordIndex];
    if (misspelledWord != null) {
      String hint =
          correctWord.substring(min(correctWord.length, misspelledWord.length));
      return TypedWord.incorrect(misspelledWord, hint);
    } else {
      return TypedWord.correct(correctWord);
    }
  }

  // Deletes the previous word. Returns true if a word was deleted.
  bool deleteFullWord() {
    // Delete whole word
    if (enteredText.isNotEmpty) {
      enteredText = '';
      return true;
    } else {
      // Try to delete previous word.
      String? previousWord = popWord();
      if (previousWord != null) {
        return true;
      }
    }
    return false;
  }

  bool onSpacePressed() {
    return onWordTyped(enteredText); // validates the rolling input;
  }

  bool deleteCharacter() {
    if (enteredText.isNotEmpty) {
      enteredText = enteredText.substring(0, enteredText.length - 1);
      return true;
    } else {
      // Since rolling input is empty, we fallback to the previous
      // word in line
      String? previousWord = popWord();
      if (previousWord != null) {
        enteredText = previousWord;
        return true;
      }
    }
    return false;
  }

  void onCharacterEntered(String character) {
    enteredText += character;
  }

  int getLineStart(int lineIndex) {
    if (lineIndex < lineStarts.length) {
      return lineStarts[lineIndex];
    } else {
      // Calculate line start
      while (lineIndex >= lineStarts.length) {
        if (lineStarts.isEmpty) {
          lineStarts
              .add(0); // after adding length of lineStarts == 1 and breaks
        } else {
          if (lineStarts.last + _getWordsInLine(lineStarts.last) >=
              words.length) {
            return -1;
          }
          lineStarts.add(lineStarts.last + _getWordsInLine(lineStarts.last));
        }
      }
      return lineStarts[lineIndex];
    }
  }

  List<TypedWord> getTypedLine(int lineIndex) {
    final List<TypedWord> typedWords = [];
    final int lineStart = getLineStart(lineIndex);
    final int lineLength = _getWordsInLine(lineStart);
    for (int i = 0; i < lineLength; i++) {
      if (lineStart + i >= currentWordIndex) {
        break;
      }
      typedWords.add(getTypedWord(lineStart + i));
    }
    return typedWords;
  }

  double getTypedWordCount() {
    // Calculate the number of words typed
    int correctCharacterCount = 0;
    int incorrectCharacterCount = 0;
    for (int i = 0; i < currentWordIndex; i++) {
      TypedWord typedWord = getTypedWord(i);
      if (typedWord.isCorrect) {
        correctCharacterCount += typedWord.value.length;
      } else {
        incorrectCharacterCount += typedWord.value.length;
      }
    }
    return (correctCharacterCount + 0.2 * incorrectCharacterCount) / 5;
  }

  void addWord(String word) {
    words.add(word);
  }

  bool onWordTyped(String word) {
    if (currentWordIndex == words.length - 1) {
      return true;
    }

    if (currentWord != word) {
      misspelledWords[currentWordIndex] = word;
    } else {
      misspelledWords.remove(currentWordIndex);
    }
    // clear rolling input and move on to the next word
    enteredText = '';
    if (currentWordIndex < words.length) {
      currentWordIndex++;
    }

    return false;
  }
}
