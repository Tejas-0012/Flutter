import 'cart_item.dart';
import 'chat_message.dart';

class GroupCart {
  final String groupId;
  final String createdBy;
  final String createdByUsername;
  final List<Member> members;
  final List<CartItem> items;
  final List<ChatMessage> comments;
  final String status;
  final Restaurant restaurant;
  final DateTime createdAt;

  GroupCart({
    required this.groupId,
    required this.createdBy,
    required this.createdByUsername,
    required this.members,
    required this.items,
    required this.comments,
    required this.status,
    required this.restaurant,
    required this.createdAt,
  });

  factory GroupCart.fromJson(Map<String, dynamic> json) {
    return GroupCart(
      groupId: json['groupId'],
      createdBy: json['createdBy'],
      createdByUsername: json['createdByUsername'],
      members: (json['members'] as List)
          .map((member) => Member.fromJson(member))
          .toList(),
      items: (json['items'] as List)
          .map((item) => CartItem.fromJson(item))
          .toList(),
      comments: (json['comments'] as List)
          .map((comment) => ChatMessage.fromJson(comment))
          .toList(),
      status: json['status'],
      restaurant: Restaurant.fromJson(json['restaurant']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  double get totalAmount {
    return items.fold(0, (total, item) => total + (item.price * item.quantity));
  }
}

class Member {
  final String userId;
  final String username;
  final DateTime joinedAt;

  Member({
    required this.userId,
    required this.username,
    required this.joinedAt,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      userId: json['userId'],
      username: json['username'],
      joinedAt: DateTime.parse(json['joinedAt']),
    );
  }
}

class Restaurant {
  final String name;
  final String id;

  Restaurant({required this.name, required this.id});

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(name: json['name'], id: json['id']);
  }
}
