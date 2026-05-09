// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';

/// Web implementation of Stockfish using a Web Worker running Stockfish.js.
/// The Worker loads the engine from CDN and communicates via postMessage,
/// matching the same stdout/stdin interface as the native Stockfish package.
class Stockfish {
  html.Worker? _worker;
  final StreamController<String> _ctrl = StreamController<String>.broadcast();

  Stockfish() {
    try {
      _worker = html.Worker('stockfish_worker.js');
      _worker!.onMessage.listen((event) {
        final msg = event.data?.toString();
        if (msg != null && msg.isNotEmpty) _ctrl.add(msg);
      });
      _worker!.onError.listen((_) {
        // Worker failed to load (e.g. offline) — engine stays unavailable
      });
    } catch (_) {
      // Web Workers not supported in this context
    }
  }

  Stream<String> get stdout => _ctrl.stream;

  set stdin(String command) {
    _worker?.postMessage(command);
  }
}
