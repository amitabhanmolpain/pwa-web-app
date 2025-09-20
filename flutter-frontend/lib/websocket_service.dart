import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  final String serverUrl;
  late WebSocketChannel channel;

  WebSocketService(this.serverUrl);

  void connect() {
    channel = WebSocketChannel.connect(Uri.parse(serverUrl));
    channel.stream.listen(
      (message) => print('Server: $message'),
      onError: (error) => print('WebSocket error: $error'),
      onDone: () => print('WebSocket closed'),
    );
  }

  void sendLocation(double lat, double lng, String tripId) {
    final data = json.encode({'tripId': tripId, 'lat': lat, 'lng': lng});
    channel.sink.add(data);
  }

  void dispose() {
    channel.sink.close();
  }
}
