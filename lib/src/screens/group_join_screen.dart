import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../context/group_cart_provider.dart';
import 'group_cart_screen.dart';

class GroupJoinScreen extends StatefulWidget {
  final String userId;
  final String username;

  const GroupJoinScreen({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  _GroupJoinScreenState createState() => _GroupJoinScreenState();
}

class _GroupJoinScreenState extends State<GroupJoinScreen> {
  final TextEditingController _groupIdController = TextEditingController();
  final bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Platter - Group Ordering'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo/Header
            const Icon(Icons.restaurant, size: 80, color: Colors.orange),
            const SizedBox(height: 20),
            const Text(
              'Group Ordering',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Create or join a group order with friends',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Group ID Input
            TextField(
              controller: _groupIdController,
              decoration: InputDecoration(
                labelText: 'Group ID (Leave empty to create new)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.group),
              ),
            ),
            const SizedBox(height: 30),

            // Buttons
            Consumer<GroupCartProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const CircularProgressIndicator();
                }

                if (provider.error != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(provider.error!),
                        backgroundColor: Colors.red,
                      ),
                    );
                    provider.clearError();
                  });
                }

                return Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => _createGroup(provider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        child: const Text(
                          'Create New Group',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    if (_groupIdController.text.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => _joinGroup(provider),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: const Text(
                            'Join Existing Group',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _createGroup(GroupCartProvider provider) async {
    await provider.createGroup(widget.userId, widget.username);

    if (provider.currentGroup != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              GroupCartScreen(userId: widget.userId, username: widget.username),
        ),
      );
    }
  }

  void _joinGroup(GroupCartProvider provider) async {
    final groupId = _groupIdController.text.trim().toUpperCase();
    if (groupId.isEmpty) return;

    await provider.joinGroup(groupId, widget.userId, widget.username);

    if (provider.currentGroup != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              GroupCartScreen(userId: widget.userId, username: widget.username),
        ),
      );
    }
  }

  @override
  void dispose() {
    _groupIdController.dispose();
    super.dispose();
  }
}
