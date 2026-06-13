import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../data/models/student_profile.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/student_profile_service.dart';
import '../../../providers/user_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // User data (in production, fetch from provider/API)
  final StudentProfileService _studentProfileService = StudentProfileService();
  StudentProfile? _profile;
  
  // Real stats from Firestore
  int _enrolledCoursesCount = 0;
  int _testsAttemptedCount = 0;
  int _leaderboardRank = 0;

  // Badges
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
    
    // Fetch tests attempted, enrolled courses, and leaderboard rank from Firestore
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    if (user != null) {
      try {
        final testsSnap = await FirebaseFirestore.instance
            .collection('testResults')
            .where('userId', isEqualTo: user.uid)
            .get();
        
        final enrollSnap = await FirebaseFirestore.instance
            .collection('enrollments')
            .where('userId', isEqualTo: user.uid)
            .get();

        final leaderboardSnap = await FirebaseFirestore.instance
            .collection('users')
            .where('isActive', isEqualTo: true)
            .orderBy('xp', descending: true)
            .get();
        final rankIndex = leaderboardSnap.docs.indexWhere((doc) => doc.id == user.uid);
        
        if (mounted) {
          setState(() {
            _testsAttemptedCount = testsSnap.docs.length;
            _enrolledCoursesCount = enrollSnap.docs.length;
            _leaderboardRank = rankIndex != -1 ? rankIndex + 1 : 0;
          });
        }
      } catch (e) {
        debugPrint('Error loading stats: $e');
      }
    }

    if (!mounted) return;
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
    final studentClass =
        _profile?.displayClassAndCourse ?? 'Complete your profile';
    final studentInitial = _profile?.initial ?? 'S';

    return Scaffold(
      body: ListView(
        children: [
          // Top Gradient Section
          _buildGradientHeader(
            xpProgress,
            studentName: studentName,
            studentClass: studentClass,
            studentInitial: studentInitial,
            xp: xp,
            nextLevelXP: nextLevelXP,
            rankName: rankName,
          ),

          // Stats Row
          _buildStatsRow(),

          // My Badges Section
          _buildBadgesSection(),

          // Menu Items
          _buildMenuSection(),
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
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 32, left: 24, right: 24, bottom: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, const Color(0xFF1a3a6b)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -20,
            right: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          // Profile Content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar with edit button
              Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.white.withOpacity(0.15),
                    child: Text(
                      studentInitial,
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () async {
                        await context.push('/profile-setup');
                        if (mounted) {
                          await _loadProfile();
                        }
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFF5A623),
                        ),
                        child: const Icon(
                          Iconsax.camera_slash,
                          color: Colors.white,
                          size: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Student name
              Text(
                studentName,
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              // Class badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  studentClass,
                  style: GoogleFonts.nunito(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // XP Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5A623).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Iconsax.medal_star,
                            color: Color(0xFFF5A623),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$rankName Rank',
                              style: GoogleFonts.nunito(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '$xp / $nextLevelXP XP',
                              style: GoogleFonts.nunito(
                                color: Colors.white.withOpacity(0.65),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5A623),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Level ${getLevelFromXP(xp)}',
                            style: GoogleFonts.nunito(
                              color: const Color(0xFF0D2240),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: xpProgress,
                        minHeight: 8,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          const Color(0xFFF5A623),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatCard(
            Iconsax.book_saved,
            const Color(0xFF0D2240),
            _enrolledCoursesCount.toString(),
            'Courses',
          ),
          _buildStatCard(
            Iconsax.clipboard_text,
            const Color(0xFF7C3AED),
            _testsAttemptedCount.toString(),
            'Tests',
          ),
          _buildStatCard(
            Iconsax.clock,
            const Color(0xFFF5A623),
            '0 hrs', // Defaults clean to 0 hrs for new users
            'Hours',
          ),
          _buildStatCard(
            Iconsax.chart_2,
            const Color(0xFF22C55E),
            _leaderboardRank > 0 ? _leaderboardRank.toString() : '-',
            'Rank',
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    IconData icon,
    Color color,
    String value,
    String label,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 11,
                color: const Color(0xFF888888),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Badges',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('View all badges'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Text(
                    'See All',
                    style: const TextStyle(
                      color: Color(0xFFF5A623),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: badges.map((badge) => _buildBadgeItem(badge)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeItem(BadgeData badge) {
    return Padding(
      padding: const EdgeInsets.only(right: 12, left: 4),
      child: Opacity(
        opacity: badge.isLocked ? 0.4 : 1.0,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: badge.isLocked
                      ? const Color(0xFFCCCCCC)
                      : const Color(0xFFF5A623),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(badge.emoji, style: const TextStyle(fontSize: 32)),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 64,
              child: Text(
                badge.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF555555),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection() {
    final menuItems = [
      MenuItemData(
        icon: Iconsax.book_saved,
        iconColor: AppColors.primary,
        title: 'My Courses',
        subtitle: _profile?.selectedCourse ?? 'View enrolled courses',
        onTap: () => context.go('/courses'),
      ),
      MenuItemData(
        icon: Iconsax.import,
        iconColor: const Color(0xFF7C3AED),
        title: 'Downloads',
        subtitle: 'Offline content',
        onTap: () => context.go('/downloads'),
      ),
      MenuItemData(
        icon: Iconsax.notification,
        iconColor: const Color(0xFFF5A623),
        title: 'Notifications',
        subtitle: 'Manage alerts',
        onTap: () => context.go('/notifications'),
      ),
      MenuItemData(
        icon: Iconsax.gift,
        iconColor: const Color(0xFF22C55E),
        title: 'Refer & Earn',
        subtitle: 'Earn rewards',
        onTap: () => _showShareDialog(),
      ),
      MenuItemData(
        icon: Icons.star_rounded,
        iconColor: const Color(0xFFFF9500),
        title: 'Rate App',
        subtitle: 'Share feedback',
        onTap: () => _launchPlayStore(),
      ),
      MenuItemData(
        icon: Iconsax.info_circle,
        iconColor: const Color(0xFF3B82F6),
        title: 'About App',
        subtitle: 'Version info',
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Account',
              style: GoogleFonts.nunito(
                color: const Color(0xFF888888),
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
          ),
          ...menuItems.map((item) => _buildMenuItem(item)).toList(),
        ],
      ),
    );
  }

  Widget _buildMenuItem(MenuItemData item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: item.isLogout
            ? const Color(0xFFDC2626).withOpacity(0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.isLogout
              ? const Color(0xFFDC2626).withOpacity(0.2)
              : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        onTap: item.onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: item.iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(item.icon, color: item.iconColor, size: 20),
        ),
        title: Text(
          item.title,
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: item.isLogout ? const Color(0xFFDC2626) : AppColors.primary,
          ),
        ),
        subtitle: Text(
          item.subtitle,
          style: GoogleFonts.nunito(
            fontSize: 11,
            color: item.isLogout
                ? const Color(0xFFDC2626).withOpacity(0.6)
                : const Color(0xFF888888),
          ),
        ),
        trailing: Icon(
          Iconsax.arrow_right_3,
          size: 18,
          color: const Color(0xFF888888),
        ),
      ),
    );
  }

  void _showShareDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Share with friends',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Share via $name')));
      },
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _launchPlayStore() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening Play Store...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About App'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Aakash Academics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text(
              'Version 1.0.0',
              style: TextStyle(fontSize: 14, color: Color(0xFF888888)),
            ),
            SizedBox(height: 12),
            Text(
              'Your partner in academic excellence',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF888888)),
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
              await AuthService().signOut();
              if (mounted) {
                await Provider.of<UserProvider>(context, listen: false).logout();
                context.go('/login');
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
            ),
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
