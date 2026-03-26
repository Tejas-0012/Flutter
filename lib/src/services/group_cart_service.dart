import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/group_cart.dart';
import '../models/cart_item.dart';

class GroupCartService {
  static const String baseUrl = 'http://localhost:4000/api/group';
  late IO.Socket socket;

  void connectSocket(String groupId, String userId, String username) {
    socket = IO.io('http://localhost:4000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.onConnect((_) {
      print('Connected to server');
      socket.emit('joinGroup', {
        'groupId': groupId,
        'userId': userId,
        'username': username,
      });
    });

    socket.onDisconnect((_) => print('Disconnected from server'));
    socket.onError((error) => print('Socket error: $error'));
  }

  void disconnectSocket() {
    socket.disconnect();
  }

  Future<GroupCart> createGroup(
    String createdBy,
    String createdByUsername,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'createdBy': createdBy,
        'createdByUsername': createdByUsername,
        'restaurant': {'name': 'Test Restaurant', 'id': '1'},
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return GroupCart.fromJson(data['groupCart']);
    } else {
      throw Exception('Failed to create group');
    }
  }

  Future<GroupCart> joinGroup(
    String groupId,
    String userId,
    String username,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/join/$groupId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'username': username}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return GroupCart.fromJson(data['groupCart']);
    } else {
      throw Exception('Failed to join group');
    }
  }

  Future<GroupCart> getGroup(String groupId) async {
    final response = await http.get(Uri.parse('$baseUrl/$groupId'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return GroupCart.fromJson(data['groupCart']);
    } else {
      throw Exception('Failed to fetch group details');
    }
  }

  // Socket event handlers
  void onCartUpdate(Function(Map<String, dynamic>) callback) {
    socket.on('cartUpdated', (data) => callback(data));
  }

  void onMessageReceived(Function(Map<String, dynamic>) callback) {
    socket.on('messageReceived', (data) => callback(data));
  }

  void onUserJoined(Function(Map<String, dynamic>) callback) {
    socket.on('userJoined', (data) => callback(data));
  }

  void onUserLeft(Function(Map<String, dynamic>) callback) {
    socket.on('userLeft', (data) => callback(data));
  }

  // Socket event emitters
  void addItem(String groupId, CartItem item, String userId, String username) {
    socket.emit('addItem', {
      'groupId': groupId,
      'item': item.toJson(),
      'userId': userId,
      'username': username,
    });
  }

  void removeItem(String groupId, String itemId, String userId) {
    socket.emit('removeItem', {
      'groupId': groupId,
      'itemId': itemId,
      'userId': userId,
    });
  }

  void updateItemQuantity(
    String groupId,
    String itemId,
    String userId,
    int quantity,
  ) {
    socket.emit('updateItemQuantity', {
      'groupId': groupId,
      'itemId': itemId,
      'userId': userId,
      'quantity': quantity,
    });
  }

  void sendMessage(
    String groupId,
    String userId,
    String username,
    String message,
  ) {
    socket.emit('sendMessage', {
      'groupId': groupId,
      'userId': userId,
      'username': username,
      'message': message,
    });
  }

  void leaveGroup(String groupId, String username) {
    socket.emit('leaveGroup', {'groupId': groupId, 'username': username});
  }
}
