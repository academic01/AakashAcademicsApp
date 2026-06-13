import 'package:flutter/material.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoId;

  const VideoPlayerScreen({super.key, required this.videoId});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Player')),
      body: Column(
        children: [
          // Video player placeholder
          Container(
            height: 250,
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_circle, color: Colors.white, size: 60),
                  const SizedBox(height: 12),
                  Text(
                    'Video: ${widget.videoId}',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          // Video details
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                const Text(
                  'Lesson Title',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Lesson Description',
                  style: TextStyle(fontSize: 14, color: Color(0xFF888888)),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Mark as complete
                  },
                  child: const Text('Mark as Complete'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
