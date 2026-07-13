import 'package:socket_io_client/socket_io_client.dart' as io;

/// Wraps the Socket.IO connection for real-time bidding + tracking.
class SocketService {
  late io.Socket socket;

  void connect(String token, {String url = 'http://10.0.2.2:4000'}) {
    socket = io.io(url, io.OptionBuilder()
        .setTransports(['websocket'])
        .setAuth({'token': token})
        .enableAutoConnect()
        .build());
  }

  void joinRide(String rideId) => socket.emit('ride:join', rideId);
  void sendBidMessage(String bidId, String body) =>
      socket.emit('bid:message', {'bidId': bidId, 'body': body});
  void sos(String rideId, double lat, double lng) =>
      socket.emit('ride:sos', {'rideId': rideId, 'lat': lat, 'lng': lng});

  void onBidNew(Function(dynamic) cb) => socket.on('bid:new', cb);
  void onBidAccepted(Function(dynamic) cb) => socket.on('bid:accepted', cb);
  void onBidMessage(Function(dynamic) cb) => socket.on('bid:message', cb);
  void onDriverLocation(Function(dynamic) cb) => socket.on('driver:location', cb);

  void dispose() => socket.dispose();
}
