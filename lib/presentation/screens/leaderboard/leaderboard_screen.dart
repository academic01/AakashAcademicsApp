import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../data/services/database_service.dart';
import '../../../providers/user_provider.dart';

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
    final userProvider = Provider.of<UserProvider>(context);
    final currentUser = userProvider.user;
    final currentUid = currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF7F8FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0D2240),
        foregroundColor: Colors.white,
        title: Text(
          'Rankings Leaderboard',
          style: GoogleFonts.nunito(
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
                  const Text('🏆', style: TextStyle(fontSize: 50)),
                  const SizedBox(height: 16),
                  Text(
                    'No rankings data yet!',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: const Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            );
          }

          final entries = snapshot.data!;
          
          // Find current user's entry and rank
          final userIndex = entries.indexWhere((e) => e['uid'] == currentUid);
          final userRank = userIndex != -1 ? userIndex + 1 : 0;
          final isUserInTop50 = userRank > 0;

          // Split into podium and list
          final podiumItems = entries.take(3).toList();
          final listItems = entries.skip(3).toList();

          return Stack(
            children: [
              Column(
                children: [
                  // Top 3 Podium
                  if (podiumItems.isNotEmpty)
                    _buildPodium(podiumItems, currentUid, isDark),
                  
                  // Scrollable list for the rest
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(16, 8, 16, (currentUser != null && !isUserInTop50) ? 90 : 20),
                      itemCount: listItems.length,
                      itemBuilder: (context, index) {
                        final entry = listItems[index];
                        final position = entry['position'] as int;
                        final name = entry['name'] ?? entry['displayName'] ?? 'Student';
                        final rankTitle = entry['rank'] ?? 'Rookie';
                        final xp = entry['xp'] ?? 0;
                        final isCurrentUser = entry['uid'] == currentUid;

                        return _buildLeaderboardRow(
                          position: position,
                          name: name,
                          rankTitle: rankTitle,
                          xp: xp,
                          isCurrentUser: isCurrentUser,
                          isDark: isDark,
                        );
                      },
                    ),
                  ),
                ],
              ),

              // Sticky Bottom Profile Rank (if not in top 50 or not in podium)
              if (currentUser != null && userRank > 3)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      border: Border(
                        top: BorderSide(
                          color: isDark ? Colors.white12 : Colors.black.withOpacity(0.08),
                          width: 2,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        children: [
                          Text(
                            '#$userRank',
                            style: GoogleFonts.nunito(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFFF5A623),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${currentUser.name} (You)',
                                  style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDark ? Colors.white : const Color(0xFF0D2240),
                                  ),
                                ),
                                Text(
                                  currentUser.rank ?? 'Rookie',
                                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${currentUser.xp} XP',
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: const Color(0xFF0D2240),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPodium(List<Map<String, dynamic>> podiumItems, String currentUid, bool isDark) {
    // We expect up to 3 items.
    // Order of podium elements horizontally: 2nd, 1st, 3rd
    final first = podiumItems.isNotEmpty ? podiumItems[0] : null;
    final second = podiumItems.length > 1 ? podiumItems[1] : null;
    final third = podiumItems.length > 2 ? podiumItems[2] : null;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF0D2240),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place
          if (second != null)
            Expanded(child: _buildPodiumColumn(second, 2, 100, currentUid, isDark)),
          
          // 1st Place
          if (first != null)
            Expanded(child: _buildPodiumColumn(first, 1, 130, currentUid, isDark)),
          
          // 3rd Place
          if (third != null)
            Expanded(child: _buildPodiumColumn(third, 3, 90, currentUid, isDark))
          else if (podiumItems.length == 2)
            // Empty placeholder for beautiful symmetry
            const Expanded(child: SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _buildPodiumColumn(
    Map<String, dynamic> user,
    int place,
    double height,
    String currentUid,
    bool isDark,
  ) {
    final isCurrentUser = user['uid'] == currentUid;
    final name = user['name'] ?? user['displayName'] ?? 'Student';
    final xp = user['xp'] ?? 0;
    
    Color podiumColor;
    String medal;
    if (place == 1) {
      podiumColor = const Color(0xFFF5A623);
      medal = '👑';
    } else if (place == 2) {
      podiumColor = const Color(0xFFC0C0C0);
      medal = '🥈';
    } else {
      podiumColor = const Color(0xFFCD7F32);
      medal = '🥉';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar stack
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: podiumColor,
                  width: isCurrentUser ? 3 : 1.5,
                ),
              ),
              child: CircleAvatar(
                radius: place == 1 ? 32 : 26,
                backgroundColor: Colors.white24,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'S',
                  style: GoogleFonts.nunito(
                    fontSize: place == 1 ? 22 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Positioned(
              top: -14,
              child: Text(
                medal,
                style: TextStyle(fontSize: place == 1 ? 22 : 18),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: place == 1 ? 13 : 12,
          ),
        ),
        Text(
          '$xp XP',
          style: GoogleFonts.nunito(
            color: podiumColor,
            fontWeight: FontWeight.w900,
            fontSize: place == 1 ? 12 : 11,
          ),
        ),
        const SizedBox(height: 10),
        // Podium block
        Container(
          height: height,
          width: 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                podiumColor.withOpacity(0.4),
                podiumColor.withOpacity(0.1),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Center(
            child: Text(
              '#$place',
              style: GoogleFonts.nunito(
                color: Colors.white.withOpacity(0.8),
                fontSize: place == 1 ? 24 : 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardRow({
    required int position,
    required String name,
    required String rankTitle,
    required int xp,
    required bool isCurrentUser,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? const Color(0xFFF5A623).withOpacity(0.15)
            : (isDark ? AppColors.darkCard : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentUser
              ? const Color(0xFFF5A623)
              : (isDark ? Colors.white12 : Colors.black.withOpacity(0.04)),
          width: isCurrentUser ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Position
          SizedBox(
            width: 32,
            child: Text(
              '#$position',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isCurrentUser ? const Color(0xFFF5A623) : Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF0D2240).withOpacity(0.1),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'S',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D2240)),
            ),
          ),
          const SizedBox(width: 12),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCurrentUser ? '$name (You)' : name,
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF0D2240),
                  ),
                ),
                Text(
                  rankTitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ],
            ),
          ),

          // XP
          Text(
            '$xp XP',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              color: const Color(0xFF0D2240),
            ),
          ),
        ],
      ),
    );
  }
}
