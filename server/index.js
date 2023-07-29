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

let timerId;
let time;

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

      console.log('Game created.');

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

  socket.on('leave-game', async ({ gameID }) => {
    try {
      let game = await Game.findById(gameID);
      if (!game.isOver) {
        game.players.forEach((p) => {
          if (p.socketID === socket.id) {
            game.players.pull(p);
          }
        });
        await game.save();
        io.to(gameID).emit('update-game-state', game);
      }
    } catch (e) {
      console.log(e);
    }
  });

  socket.on('restart-timer', async ({ gameID }) => {
    try {
      let game = await Game.findById(gameID);

      console.log('Resetting game...');

      // reset game
      const sentence = await getSentence();
      game.sentence = sentence;
      game.isOver = false;
      game.players.forEach((p) => {
        p.typedWords = 0;
        p.WPM = -1;
        p.currentWordIndex = 0;
      });

      game.startTime = new Date().getTime();
      await game.save();
      await startGameClock(gameID);
      io.to(gameID).emit('update-game-state', game);
    } catch (e) {
      console.log(e);
    }
  });

  socket.on('timer', async ({ playerId, gameID }) => {
    let game;
    let countDown = 5;

    console.log('Start countdown timer.');

    try {
      game = await Game.findById(gameID);
    } catch (e) {
      socket.emit('error', e.message);
    }
    clearInterval(timerId);

    // only the party leader can start the game
    let timer = setInterval(async () => {
      if (countDown >= 0) {
        io.to(gameID).emit('timer', {
          countDown,
          msg: 'Game Starting in...',
        });
        console.log(countDown);
        countDown--;
      } else {
        game.isJoin = false;
        await game.save();
        await startGameClock(gameID).then(() => {
          io.to(gameID).emit('update-game-state', game);
          // stop the timer
          clearInterval(timer);
        });
      }
    }, 1000);
  });

  socket.on('user-input', async ({ currentWordIndex, typedWordCount, gameID }) => {
    let game = await Game.findById(gameID);
    // game is in progress
    if (!game.isJoin && !game.isOver) {
      let player = game.players.find((p) => p.socketID === socket.id);

      player.currentWordIndex = currentWordIndex;
      player.typedWords = typedWordCount;

      if (time >= 0) {
        if (player.currentWordIndex < game.words.length) {
          console.log('ping!');
          game = await game.save();
          console.log(`Saving game... ${game}`);
          io.to(gameID).emit('update-game-state', game);
        } else {
          let endTime = new Date().getTime();
          let startTime = game.startTime;
          console.log('Computing WPM for player...');
          player.WPM = calculateWPM(endTime, startTime, typedWordCount);

          // check if all players have their wpm calculated
          isOver = true;
          game.players.forEach((player) => {
            if (player.WPM === -1) {
              isOver = false;
            }
          });

          if (isOver) {
            console.log('All players have finished. Game over.');
            game.isOver = true;
          }

          game = await game.save();
          isOver ? io.to(gameID).emit('done') : socket.emit('done');
          clearInterval(timerId);
          io.to(gameID).emit('update-game-state', game);
        }
      }
    }
  });
});

const startGameClock = async (gameID) => {
  time = 60;
  let game = await Game.findById(gameID);
  game.startTime = new Date().getTime();
  game = await game.save();

  console.log('Starting game clock.');

  timerId = setInterval(() => {
    if (time >= 0) {
      const timeFormat = calculateTime(time);
      io.to(gameID).emit('timer', {
        countDown: timeFormat,
        msg: 'Time Remaining',
      });
      console.log(time);
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
          console.log(`Saving game... ${game}`);
          io.to(gameID).emit('done');
          io.to(gameID).emit('update-game-state', game);
          clearInterval(timerId);
        } catch (e) {
          console.log(e);
        }
      })();
    }
  }, 1000);
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
