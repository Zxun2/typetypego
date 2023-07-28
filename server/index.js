const express = require('express');
const http = require('http');
const mongoose = require('mongoose');
const { getSentence, calculateWPM, calculateTime } = require('./utils');
const { Game } = require('./models');
const dotenv = require('dotenv');

dotenv.config({ path: './.env' });
const app = express();
const port = process.env.PORT || 3000;
var server = http.createServer(app);
var io = require('socket.io')(server);

app.use(express.json()); // for parsing application/json

const db = process.env.DATABASE;

io.on('connection', (socket) => {
  socket.on('create-game', async ({ nickname }) => {
    try {
      let game = new Game();
      const sentence = await getSentence();
      game.words = sentence;
      let player = {
        socketID: socket.id,
        nickname,
        isPartyLeader: true,
      };
      game.players.push(player);
      game = await game.save();

      const gameId = game._id.toString();
      // joins the game room
      socket.join(gameId);

      // sends the game id back to the client
      io.to(gameId).emit('update-game', game);
    } catch (e) {
      console.log(e);
    }
  });

  socket.on('join-game', async ({ nickname, gameId }) => {
    try {
      if (!gameId.match(/^[0-9a-fA-F]{24}$/)) {
        socket.emit('error', 'Please enter a valid game ID');
        return;
      }
      let game = await Game.findById(gameId);

      if (game.isJoin && game.players.length < 4) {
        const id = game._id.toString();
        let player = {
          nickname,
          socketID: socket.id,
        };
        socket.join(id);
        game.players.push(player);
        game = await game.save();
        io.to(gameId).emit('update-game', game);
      } else {
        socket.emit('error', 'The game is currently in progress, please try again later!');
      }
    } catch (e) {
      console.log(e);
    }
  });

  socket.on('timer', async ({ playerId, gameID }) => {
    let game;
    let player;
    let countDown = 5;

    console.log('Start countdown timer.');

    try {
      game = await Game.findById(gameID);
      player = game.players.id(playerId);
    } catch (e) {
      socket.emit('error', e.message);
    }

    // only the party leader can start the game
    if (player.isPartyLeader) {
      let timerId = setInterval(async () => {
        if (countDown >= 0) {
          io.to(gameID).emit('timer', {
            countDown,
            msg: 'Game Starting in...',
          });
          console.log(countDown);
          countDown--;
        } else {
          game.isJoin = false;
          game = await game.save();

          io.to(gameID).emit('update-game-state', game);
          startGameClock(gameID);

          // stop the timer
          clearInterval(timerId);
        }
      }, 1000);
    }
  });

  socket.on('user-input', async ({ currentWordIndex, typedWordCount, gameID }) => {
    let game = await Game.findById(gameID);
    // game is in progress
    if (!game.isJoin && !game.isOver) {
      let player = game.players.find((p) => p.socketID === socket.id);

      player.currentWordIndex = currentWordIndex;
      player.typedWords = typedWordCount;

      if (player.currentWordIndex < game.words.length - 1) {
        game = await game.save();
        io.to(gameID).emit('update-game-state', game);
      } else {
        let endTime = new Date().getTime();
        let startTime = game.startTime;
        player.WPM = calculateWPM(endTime, startTime, typedWordCount);
        game = await game.save();
        socket.emit('done');
        io.to(gameID).emit('update-game-state', game);
      }
    }
  });
});

const startGameClock = async (gameID) => {
  let time = 10;
  let game = await Game.findById(gameID);
  game.startTime = new Date().getTime();
  game = await game.save();

  let timerId = setInterval(
    (function gameIntervalFunc() {
      if (time >= 0) {
        const timeFormat = calculateTime(time);
        io.to(gameID).emit('timer', {
          countDown: timeFormat,
          msg: 'Time Remaining',
        });
        time--;
      } else {
        (async () => {
          try {
            let endTime = new Date().getTime();
            let game = await Game.findById(gameID);
            game.isOver = true;
            game.players.forEach((player) => {
              if (player.WPM === -1) {
                player.WPM = calculateWPM(endTime, game.startTime, player.typedWords);
              }
            });
            game = await game.save();
            io.to(gameID).emit('done');
            io.to(gameID).emit('update-game-state', game);
            clearInterval(timerId);
          } catch (e) {
            console.log(e);
          }
        })();
      }
      return gameIntervalFunc;
    })(),
    1000
  );
};

mongoose
  .connect(db)
  .then(() => {
    console.log('Database connection successful! 🚀');
  })
  .catch((e) => {
    console.log(e);
  });

server.listen(port, '0.0.0.0', () => {
  console.log(`Server started and running on port ${port}`);
});
