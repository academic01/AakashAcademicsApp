import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/gradients.dart';
import '../../../data/models/student_profile.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/database_service.dart';
import '../../../data/services/student_profile_service.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/theme_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final StudentProfileService _studentProfileService = StudentProfileService();
  final DatabaseService _dbService = DatabaseService();
  StudentProfile? _profile;
  
  int _enrolledCoursesCount = 0;
  int _testsAttemptedCount = 0;
  int _leaderboardRank = 0;

  final List<BadgeData> badges = [
    BadgeData(emoji: '🎯', name: 'First Test', isLocked: false),
    BadgeData(emoji: '⚡', name: '7 Day Streak', isLocked: false),
    BadgeData(emoji: '🏆', name: 'Top Scorer', isLocked: true),
    BadgeData(emoji: '🔥', name: 'Perfect Score', isLocked: true),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _studentProfileService.loadProfile();
    if (!mounted) return;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    if (user != null) {
      _dbService.streamTestResultsCount(user.uid).listen((resultsCount) {
        if (mounted) setState(() => _testsAttemptedCount = resultsCount);
      });

      _dbService.streamEnrollmentsCount(user.uid).listen((coursesCount) {
        if (mounted) setState(() => _enrolledCoursesCount = coursesCount);
      });

      _dbService.streamLeaderboard().listen((entries) {
        if (mounted) {
          final rankIndex = entries.indexWhere((e) => e['uid'] == user.uid);
          setState(() {
            _leaderboardRank = rankIndex != -1 ? rankIndex + 1 : 0;
          });
        }
      });
    }

    setState(() => _profile = profile);
  }

  int getLevelFromXP(int xp) {
    if (xp >= 15000) return 5;
    if (xp >= 7000) return 4;
    if (xp >= 3000) return 3;
    if (xp >= 1000) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;
    
    final xp = user?.xp ?? 0;
    final rankName = user?.rank ?? 'Rookie';

    int nextLevelXP = 1000;
    if (xp >= 15000) {
      nextLevelXP = 30000;
    } else if (xp >= 7000) {
      nextLevelXP = 15000;
    } else if (xp >= 3000) {
      nextLevelXP = 7000;
    } else if (xp >= 1000) {
      nextLevelXP = 3000;
    } else {
      nextLevelXP = 1000;
    }

    final double xpProgress = (xp / nextLevelXP).clamp(0.0, 1.0);
    final studentName = _profile?.fullName ?? 'Student';
    final studentClass = _profile?.displayClassAndCourse ?? 'Complete your profile';
    final studentInitial = _profile?.initial ?? 'S';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : const Color(0xFFF7F8FC);
    final cardBgColor = isDark ? AppColors.darkCard : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          // Redesigned Top Header: soft navy-to-lavender gradient background
          _buildGradientHeader(
            xpProgress,
            studentName: studentName,
            studentClass: studentClass,
            studentInitial: studentInitial,
            xp: xp,
            nextLevelXP: nextLevelXP,
            rankName: rankName,
            isDark: isDark,
            cardBgColor: cardBgColor,
          ),

          // 2x2 Stats Grid Redesigned
          _buildStatsGrid(isDark, cardBgColor),

          // Redesigned My Badges
          _buildBadgesSection(isDark, cardBgColor),

          // Menu section
          _buildMenuSection(isDark, cardBgColor),
        ],
      ),
    );
  }

  Widget _buildGradientHeader(
    double xpProgress, {
    required String studentName,
    required String studentClass,
    required String studentInitial,
    required int xp,
    required int nextLevelXP,
    required String rankName,
    required bool isDark,
    required Color cardBgColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
              : [const Color(0xFFE0E7FF), const Color(0xFFF1F5F9)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // Floating profile info card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                // Circular progress ring around avatar showing level progress
                CircularPercentIndicator(
                  radius: 42.0,
                  lineWidth: 5.0,
                  percent: xpProgress,
                  center: CircleAvatar(
                    radius: 36,
                    backgroundColor: const Color(0xFF4F46E5).withValues(alpha: 0.15),
                    child: Text(
                      studentInitial,
                      style: GoogleFonts.nunito(
                        color: const Color(0xFF4F46E5),
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  circularStrokeCap: CircularStrokeCap.round,
                  progressColor: const Color(0xFF4F46E5),
                  backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName,
                        style: GoogleFonts.nunito(
                          color: isDark ? Colors.white : const Color(0xFF0D2240),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          studentClass,
                          style: GoogleFonts.nunito(
                            color: const Color(0xFF4F46E5),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Iconsax.edit, size: 20),
                  onPressed: () async {
                    await context.push('/profile-setup');
                    _loadProfile();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // XP and progress
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$rankName Rank',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    Text(
                      '$xp / $nextLevelXP XP',
                      style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5A623),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Lvl ${getLevelFromXP(xp)}',
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(bool isDark, Color cardBgColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
        children: [
          _buildGridStatCard('Courses', _enrolledCoursesCount.toString(), AppGradients.school, '📚'),
          _buildGridStatCard('Tests', _testsAttemptedCount.toString(), AppGradients.boards, '🎯'),
          _buildGridStatCard('Hours', '0 hrs', AppGradients.govtJobs, '⚡'),
          _buildGridStatCard('Rank', _leaderboardRank > 0 ? '#$_leaderboardRank' : '-', AppGradients.cuet, '🏆'),
        ],
      ),
    );
  }

  Widget _buildGridStatCard(String label, String value, LinearGradient gradient, String emoji) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 8,
            bottom: -5,
            child: Opacity(
              opacity: 0.15,
              child: Text(emoji, style: const TextStyle(fontSize: 50, fontFamily: 'Emoji')),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white70, letterSpacing: 0.8),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesSection(bool isDark, Color cardBgColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Badges',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('See All →', style: TextStyle(color: Color(0xFFF5A623), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: badges.length,
            itemBuilder: (context, index) {
              final badge = badges[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Opacity(
                  opacity: badge.isLocked ? 0.45 : 1.0,
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: badge.isLocked ? Colors.grey[200] : null,
                          gradient: badge.isLocked ? null : AppGradients.cuet,
                          boxShadow: badge.isLocked
                              ? null
                              : [
                                  BoxShadow(
                                    color: AppGradients.cuet.colors.first.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  )
                                ],
                        ),
                        child: Center(
                          child: Text(
                            badge.emoji,
                            style: const TextStyle(fontSize: 26, fontFamily: 'Emoji'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        badge.name,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection(bool isDark, Color cardBgColor) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isThemeDark = themeProvider.isDarkMode;

    final menuItems = [
      MenuItemData(
        icon: Iconsax.book_saved,
        iconColor: const Color(0xFF4F46E5),
        title: 'My Courses',
        subtitle: _profile?.selectedCourse ?? 'View enrolled courses',
        onTap: () => context.go('/courses'),
      ),
      MenuItemData(
        icon: Iconsax.message_question,
        iconColor: const Color(0xFF7C3AED),
        title: 'My Doubts',
        subtitle: 'View asked questions',
        onTap: () => context.push('/my-doubts'),
      ),
      MenuItemData(
        icon: Iconsax.box,
        iconColor: const Color(0xFF10B981),
        title: 'My Test Packages',
        subtitle: 'View purchased packages',
        onTap: () => context.push('/my-packages'),
      ),
      MenuItemData(
        icon: isThemeDark ? Iconsax.sun_1 : Iconsax.moon,
        iconColor: const Color(0xFFEC4899),
        title: 'Theme Mode',
        subtitle: isThemeDark ? 'Dark Mode' : 'Light Mode',
        onTap: () {
          themeProvider.toggleTheme(!isThemeDark);
        },
      ),
      MenuItemData(
        icon: Iconsax.notification,
        iconColor: const Color(0xFFF5A623),
        title: 'Notifications',
        subtitle: 'Manage alerts',
        onTap: () {},
      ),
      MenuItemData(
        icon: Iconsax.gift,
        iconColor: const Color(0xFF059669),
        title: 'Refer & Earn',
        subtitle: 'Earn rewards with friends',
        onTap: () => _showShareDialog(),
      ),
      MenuItemData(
        icon: Iconsax.info_circle,
        iconColor: const Color(0xFF3B82F6),
        title: 'About App',
        subtitle: 'Version & info',
        onTap: () => _showAboutDialog(),
      ),
      MenuItemData(
        icon: Iconsax.logout,
        iconColor: const Color(0xFFDC2626),
        title: 'Logout',
        subtitle: 'Sign out of account',
        onTap: () => _showLogoutDialog(),
        isLogout: true,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ACCOUNT SETTINGS',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1.2),
          ),
          const SizedBox(height: 10),
          ...menuItems.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: item.isLogout
                    ? const Color(0xFFDC2626).withValues(alpha: 0.04)
                    : cardBgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: item.isLogout
                      ? const Color(0xFFDC2626).withValues(alpha: 0.2)
                      : (isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB)),
                ),
              ),
              child: ListTile(
                onTap: item.onTap,
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: item.iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: item.iconColor, size: 18),
                ),
                title: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: item.isLogout ? const Color(0xFFDC2626) : (isDark ? Colors.white : const Color(0xFF0D2240)),
                  ),
                ),
                subtitle: Text(
                  item.subtitle,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                trailing: const Icon(Iconsax.arrow_right_3, size: 16, color: Colors.grey),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showShareDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Refer Friends',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildShareOption('WhatsApp', '💬'),
                _buildShareOption('Facebook', '👥'),
                _buildShareOption('Twitter', '𝕏'),
                _buildShareOption('Instagram', '📷'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(String name, String emoji) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Share via $name')));
      },
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('About App'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Aakash Academics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 8),
            Text(
              'Version 1.0.0',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            SizedBox(height: 12),
            Text(
              'Excellence in Online Learning',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = Provider.of<UserProvider>(context, listen: false);
              await AuthService().signOut();
              await provider.logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class BadgeData {
  final String emoji;
  final String name;
  final bool isLocked;

  BadgeData({required this.emoji, required this.name, required this.isLocked});
}

class MenuItemData {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLogout;

  MenuItemData({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isLogout = false,
  });
}
