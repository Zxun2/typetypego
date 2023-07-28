import 'package:socket_io_client/socket_io_client.dart';

// Creates a singleton SocketClient class
class SocketClient {
  Socket? socket;
  static SocketClient? _instance;

  SocketClient._internal() {
    socket = io(
        'https://typetypego-server.onrender.com',
        // 'http://localhost:3000',
        <String, dynamic>{
          'transports': ['websocket'],
          'autoConnect': false,
        });
    socket!.connect();
  }

  static SocketClient get instance {
    _instance ??= SocketClient._internal();
    return _instance!;
  }
}
