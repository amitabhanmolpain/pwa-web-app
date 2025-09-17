import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'logger_setup.dart';

class TripService {
  final String wsUrl = 'ws://your-server:8080/trip/socket';
  WebSocketChannel? _channel;

  // Connect to WebSocket
  Future<void> connect() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        logger.warning('No access token found. Cannot connect WebSocket.');
        return;
      }

      _channel = WebSocketChannel.connect(
        Uri.parse('$wsUrl?token=$token'),
      );

      _channel!.stream.listen(
        (message) {
          logger.info('Received from WebSocket: $message');
        },
        onError: (error) {
          logger.severe('WebSocket error: $error');
        },
        onDone: () {
          logger.info('WebSocket closed.');
        },
      );

      logger.info('WebSocket connected.');
    } catch (e, st) {
      logger.severe('Failed to connect WebSocket: $e\n$st');
    }
  }

  // Send location updates
  void sendLocation(double lat, double lng) {
    if (_channel == null) {
      logger.warning('WebSocket not connected. Cannot send location.');
      return;
    }

    final data = json.encode({
      'latitude': lat,
      'longitude': lng,
      'timestamp': DateTime.now().toIso8601String(),
    });

    _channel!.sink.add(data);
    logger.info('Sent location: $data');
  }

  // Disconnect WebSocket
  void disconnect() {
    _channel?.sink.close();
    logger.info('WebSocket disconnected.');
  }
}
