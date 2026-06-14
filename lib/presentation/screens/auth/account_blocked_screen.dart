import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/app_constants.dart';

class AccountBlockedScreen extends StatelessWidget {
  const AccountBlockedScreen({super.key});

  Future<void> _contactSupport(BuildContext context) async {
    String phone = '+919999999999'; // Fallback admin phone
    String email = 'support@aakashacademics.com';

    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('site_settings')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        phone = data['contactPhone'] ?? data['supportWhatsapp'] ?? phone;
        email = data['contactEmail'] ?? email;
      }
    } catch (_) {}

    final whatsappUrl = Uri.parse('https://wa.me/${phone.replaceAll('+', '').replaceAll(' ', '')}?text=My%20account%20has%20been%20suspended.%20Please%20help.');
    
    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      final mailUrl = Uri.parse('mailto:$email?subject=Account%20Suspended');
      if (await canLaunchUrl(mailUrl)) {
        await launchUrl(mailUrl);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open WhatsApp or email client.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : const Color(0xFFF7F8FC);
    final cardBgColor = isDark ? AppColors.darkCard : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_person_rounded,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Account Suspended',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0D2240),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your account has been temporarily suspended. Please contact support for assistance.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => _contactSupport(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D2240),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Contact Support',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    final prefs = await SharedPreferences.getInstance();
                    // Clear login states specifically
                    await prefs.remove(StorageKeys.isLoggedIn);
                    await prefs.remove(StorageKeys.userId);
                    await prefs.remove(StorageKeys.profileComplete);
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                  child: const Text(
                    'Back to Login',
                    style: TextStyle(
                      color: Color(0xFFF5A623),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
