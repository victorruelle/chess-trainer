// Runs Stockfish.js inside a Web Worker so it doesn't block the UI thread.
// Stockfish.js is the official JavaScript/WASM port of the Stockfish engine.
importScripts('https://cdn.jsdelivr.net/npm/stockfish.js@10.0.2/stockfish.js');

var engine = STOCKFISH();

// Forward engine output back to the main thread
engine.onmessage = function (msg) {
  var text = (typeof msg === 'string') ? msg : (msg.data || '');
  if (text) postMessage(text);
};

// Forward commands from main thread into the engine
onmessage = function (event) {
  engine.postMessage(event.data);
};
