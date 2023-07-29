const axios = require('axios');

const getSentence = async () => {
  // const jokeData = await axios
  //   .get('https://api.quotable.io/quotes/random?minLength=100&maxLength=150')
  //   .then((res) => res.data[0].content.split(' '));
  // return jokeData;
  return 'Kindness in words creates confidence. You are ultra gay but i am okay with that. Please do not do that again though.'.split(
    ' '
  );
};

const calculateTime = (time) => {
  let min = Math.floor(time / 60);
  let sec = time % 60;
  return `${min}:${sec < 10 ? '0' + sec : sec}`;
};

const calculateWPM = (endTime, startTime, wordCount) => {
  const timeTakenInSec = (endTime - startTime) / 1000;
  const timeTaken = timeTakenInSec / 60;
  const WPM = Math.floor(wordCount / timeTaken);
  return WPM;
};

module.exports = {
  getSentence,
  calculateTime,
  calculateWPM,
};
