import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentPendingScreen extends StatelessWidget {
  final String itemTitle;
  final double amount;

  const PaymentPendingScreen({
    super.key,
    required this.itemTitle,
    required this.amount,
  });

  Future<void> _openWhatsApp() async {
    final url = Uri.parse('https://wa.me/919999999999?text=Hello%2C%20I%20have%20submitted%20a%20payment%20for%20verification.');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hourglass_empty,
                  color: Colors.amber,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '⏳ Payment Under Review',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0D2240),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Amount: ₹${amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D2240),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'for "$itemTitle"',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Steps Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📋 What happens next?',
                      style: TextStyle(
                        color: Color(0xFFE65C00),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStep('1', 'Our team reviews your payment screenshot'),
                    _buildStep('2', 'Verification within 2 hours'),
                    _buildStep('3', 'You get instant access once verified'),
                    _buildStep('4', "You'll receive a notification when approved"),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Contact Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Need help? Contact us:',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _openWhatsApp,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text(
                            ' WhatsApp Support',
                            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () => context.go('/home'),
                child: const Text(
                  'Back to Home',
                  style: TextStyle(
                    color: Color(0xFF0D2240),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String index, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 9,
            backgroundColor: const Color(0xFFE65C00),
            child: Text(
              index,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFF0D2240), fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
