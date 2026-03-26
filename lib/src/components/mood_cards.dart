import 'package:flutter/material.dart';

class MoodCards extends StatelessWidget {
  final Function(String) onMoodSelect;
  final Map<String, dynamic>? userLocation;

  MoodCards({super.key, required this.onMoodSelect, this.userLocation});

  final List<Map<String, dynamic>> moods = [
    {
      'id': '1',
      'emoji': '🍝',
      'name': 'Comfort Food',
      'color': Color(0xFFFFB74D),
      'climateTags': ['comfort', 'hearty', 'warming'],
    },
    {
      'id': '2',
      'emoji': '💪',
      'name': 'Health Kick',
      'color': Color(0xFF81C784),
      'climateTags': ['light', 'refreshing', 'hydrating'],
    },
    {
      'id': '3',
      'emoji': '🎉',
      'name': 'Celebrating',
      'color': Color(0xFFBA68C8),
      'climateTags': ['spicy', 'fried', 'hot', 'cold'],
    },
    {
      'id': '4',
      'emoji': '💑',
      'name': 'Date Night',
      'color': Color(0xFFF06292),
      'climateTags': ['comfort', 'romantic'],
    },
    {
      'id': '5',
      'emoji': '😴',
      'name': 'Lazy Day',
      'color': Color(0xFF4FC3F7),
      'climateTags': ['comfort', 'quick'],
    },
    {
      'id': '6',
      'emoji': '🏃',
      'name': 'Quick Bite',
      'color': Color(0xFF4DD0E1),
      'climateTags': ['quick', 'light'],
    },
  ];

  void _handleMoodPress(String moodName) {
    onMoodSelect(moodName);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: moods.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemBuilder: (context, index) {
          final mood = moods[index];
          return _buildMoodCard(
            mood['emoji'] as String,
            mood['name'] as String,
            mood['color'] as Color,
          );
        },
      ),
    );
  }

  Widget _buildMoodCard(String emoji, String name, Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleMoodPress(name),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 100,
          height: 130,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                offset: const Offset(0, 2),
                blurRadius: 3.84,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ),
              if (userLocation != null) ...[
                const SizedBox(height: 4),
                Text(
                  '🌡️ Weather-aware',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
