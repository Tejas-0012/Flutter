import 'package:flutter/foundation.dart';
import '../models/group_cart.dart';
import '../models/cart_item.dart';
import '../models/chat_message.dart';
import '../services/group_cart_service.dart';

class GroupCartProvider with ChangeNotifier {
  final GroupCartService _service = GroupCartService();

  GroupCart? _currentGroup;
  List<CartItem> _cartItems = [];
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _error;

  GroupCart? get currentGroup => _currentGroup;
  List<CartItem> get cartItems => _cartItems;
  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get totalAmount =>
      _cartItems.fold(0, (total, item) => total + (item.price * item.quantity));

  Future<void> createGroup(String userId, String username) async {
    _setLoading(true);
    try {
      _currentGroup = await _service.createGroup(userId, username);
      _cartItems = _currentGroup!.items;
      _messages = _currentGroup!.comments;
      _service.connectSocket(_currentGroup!.groupId, userId, username);
      _setupSocketListeners();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> joinGroup(String groupId, String userId, String username) async {
    _setLoading(true);
    try {
      _currentGroup = await _service.joinGroup(groupId, userId, username);
      _cartItems = _currentGroup!.items;
      _messages = _currentGroup!.comments;
      _service.connectSocket(groupId, userId, username);
      _setupSocketListeners();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _setupSocketListeners() {
    _service.onCartUpdate((data) {
      _cartItems = (data['items'] as List)
          .map((item) => CartItem.fromJson(item))
          .toList();
      notifyListeners();
    });

    _service.onMessageReceived((data) {
      _messages.add(
        ChatMessage(
          userId: data['userId'],
          username: data['username'],
          message: data['message'],
          timestamp: DateTime.parse(data['timestamp']),
        ),
      );
      notifyListeners();
    });

    _service.onUserJoined((data) {
      // Handle user joined notification
      _messages.add(
        ChatMessage(
          userId: 'system',
          username: 'System',
          message: data['message'],
          timestamp: DateTime.now(),
        ),
      );
      notifyListeners();
    });

    _service.onUserLeft((data) {
      // Handle user left notification
      _messages.add(
        ChatMessage(
          userId: 'system',
          username: 'System',
          message: data['message'],
          timestamp: DateTime.now(),
        ),
      );
      notifyListeners();
    });
  }

  void addItem(CartItem item, String userId, String username) {
    _service.addItem(_currentGroup!.groupId, item, userId, username);
  }

  void removeItem(String itemId, String userId) {
    _service.removeItem(_currentGroup!.groupId, itemId, userId);
  }

  void updateItemQuantity(String itemId, String userId, int quantity) {
    _service.updateItemQuantity(
      _currentGroup!.groupId,
      itemId,
      userId,
      quantity,
    );
  }

  void sendMessage(String userId, String username, String message) {
    _service.sendMessage(_currentGroup!.groupId, userId, username, message);
  }

  void leaveGroup(String username) {
    if (_currentGroup != null) {
      _service.leaveGroup(_currentGroup!.groupId, username);
      _service.disconnectSocket();
      _resetState();
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _resetState() {
    _currentGroup = null;
    _cartItems = [];
    _messages = [];
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
