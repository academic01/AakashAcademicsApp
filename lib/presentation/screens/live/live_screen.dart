import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LiveScreen extends StatelessWidget {
  const LiveScreen({Key? key}) : super(key: key);

  static final Uri _youtubeUri = Uri.parse(
    'https://youtube.com/@aakashacademics?si=8GuakKRMyoO5Ef-K&themeRefresh=1',
  );

  Future<void> _openYoutube(BuildContext context) async {
    if (await canLaunchUrl(_youtubeUri)) {
      await launchUrl(_youtubeUri, mode: LaunchMode.externalApplication);
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open YouTube right now. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Live Classes')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF0000).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.ondemand_video_rounded,
                    size: 52,
                    color: Color(0xFFFF0000),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Catch Us Live on YouTube!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0D2240),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'We are currently hosting all our interactive live classes and doubt-clearing sessions on our official YouTube channel. Subscribe and hit the bell icon so you never miss an update.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openYoutube(context),
                    icon: const Icon(Icons.play_circle_fill_rounded),
                    label: const Text('Watch Live on YouTube'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF0000),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
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
