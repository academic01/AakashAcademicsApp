import 'package:cloud_firestore/cloud_firestore.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
        title: Text(
          'Leaderboard',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0D2240),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _dbService.streamLeaderboard(),
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
                        : (isDark ? AppColors.darkCard : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: position <= 3
                          ? medalColor.withOpacity(0.3)
                          : (isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB)),
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
                                color: isDark ? Colors.white : const Color(0xFF0D2240),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              rank,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: isDark ? AppColors.textMutedDark : const Color(0xFF888888),
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
                              color: isDark ? AppColors.secondary : AppColors.primary,
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
