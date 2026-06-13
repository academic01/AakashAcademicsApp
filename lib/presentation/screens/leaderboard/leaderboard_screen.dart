import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../data/services/database_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final DatabaseService _dbService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Leaderboard',
          style: TextStyle(
            color: Color(0xFF0D2240),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _dbService.getLeaderboard(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people, size: 64, color: Color(0xFFCCCCCC)),
                  const SizedBox(height: 16),
                  Text(
                    'No leaderboard data',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: const Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            );
          }

          final entries = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final position = entry['position'] as int;
                final rank = entry['rank'] ?? 'Rookie';
                final xp = entry['xp'] ?? 0;
                final name =
                    entry['displayName'] ??
                    entry['name'] ??
                    'User ${entry['uid']?.substring(0, 6)}';

                // Determine medal/badge
                String medal = '';
                Color medalColor = Colors.grey;
                if (position == 1) {
                  medal = '🥇';
                  medalColor = const Color(0xFFFFD700);
                } else if (position == 2) {
                  medal = '🥈';
                  medalColor = const Color(0xFFC0C0C0);
                } else if (position == 3) {
                  medal = '🥉';
                  medalColor = const Color(0xFFCD7F32);
                }

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: position <= 3
                        ? medalColor.withOpacity(0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: position <= 3
                          ? medalColor.withOpacity(0.3)
                          : const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      // Position
                      SizedBox(
                        width: 40,
                        child: Row(
                          children: [
                            if (medal.isNotEmpty)
                              Text(medal, style: const TextStyle(fontSize: 20))
                            else
                              Text(
                                '#$position',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF888888),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // User Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.labelLarge.copyWith(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0D2240),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              rank,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: const Color(0xFF888888),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // XP
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$xp XP',
                            style: AppTextStyles.labelLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Icon(
                            Icons.trending_up,
                            size: 14,
                            color: Color(0xFF22C55E),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
