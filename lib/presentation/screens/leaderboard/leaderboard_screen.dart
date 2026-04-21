import 'package:flutter/material.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final List<_LeaderboardEntry> _entries = [
    _LeaderboardEntry(1, 'Raj Kumar', 95.5, true),
    _LeaderboardEntry(2, 'Priya Singh', 93.2, false),
    _LeaderboardEntry(3, 'Arjun Patel', 91.8, false),
    _LeaderboardEntry(4, 'Neha Gupta', 90.5, false),
    _LeaderboardEntry(5, 'Current User', 87.5, true),
    _LeaderboardEntry(6, 'Aditya Sharma', 86.2, false),
    _LeaderboardEntry(7, 'Anjali Verma', 85.0, false),
    _LeaderboardEntry(8, 'Vivek Kumar', 84.5, false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: Column(
        children: [
          // Filter tabs
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFilterButton('All Time', true),
                _buildFilterButton('This Month', false),
                _buildFilterButton('This Week', false),
              ],
            ),
          ),
          // Leaderboard list
          Expanded(
            child: ListView.builder(
              itemCount: _entries.length,
              itemBuilder: (context, index) {
                final entry = _entries[index];
                return _buildLeaderboardTile(entry);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, bool isActive) {
    return ElevatedButton(
      onPressed: () {
        // TODO: Change filter
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive
            ? const Color(0xFF0D2240)
            : const Color(0xFFF9F9F9),
        foregroundColor: isActive ? Colors.white : const Color(0xFF888888),
        elevation: 0,
      ),
      child: Text(label),
    );
  }

  Widget _buildLeaderboardTile(_LeaderboardEntry entry) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: entry.isCurrentUser ? const Color(0xFFF9F9F9) : Colors.white,
        border: Border.all(
          color: entry.isCurrentUser
              ? const Color(0xFF0D2240)
              : const Color(0xFFE5E5E5),
          width: entry.isCurrentUser ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: entry.rank <= 3
                  ? const Color(0xFF0D2240)
                  : const Color(0xFFF9F9F9),
            ),
            child: Center(
              child: Text(
                '${entry.rank}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: entry.rank <= 3
                      ? Colors.white
                      : const Color(0xFF0D2240),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${entry.score} points',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),
          // Score display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${entry.score}%',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF22C55E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardEntry {
  final int rank;
  final String name;
  final double score;
  final bool isCurrentUser;

  _LeaderboardEntry(this.rank, this.name, this.score, this.isCurrentUser);
}
