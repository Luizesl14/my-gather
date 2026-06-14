import "dart:async";
import "dart:convert";

import "package:web_socket_channel/web_socket_channel.dart";

class RealtimeService {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get stream => _controller.stream;
  bool get isConnected => _channel != null;

  void connect(String wsUrl, String token) {
    disconnect();
    final uri = Uri.parse("$wsUrl?token=$token");
    _channel = WebSocketChannel.connect(uri);
    _sub = _channel!.stream.listen(
      (data) {
        if (data is! String) return;
        try {
          final decoded = jsonDecode(data);
          if (decoded is Map<String, dynamic>) _controller.add(decoded);
        } catch (_) {}
      },
      onDone: _onClose,
      onError: (_) => _onClose(),
      cancelOnError: false,
    );
  }

  void send(Map<String, dynamic> event) {
    if (_channel == null) return;
    _channel!.sink.add(jsonEncode(event));
  }

  void disconnect() {
    _sub?.cancel();
    _channel?.sink.close();
    _channel = null;
    _sub = null;
  }

  void dispose() {
    disconnect();
    _controller.close();
  }

  void _onClose() {
    _channel = null;
    _sub = null;
  }
}
