import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LiveVideoEmbedScreen extends StatefulWidget {
  final String streamUrl;
  final String title;
  final String facultyName;

  const LiveVideoEmbedScreen({
    super.key,
    required this.streamUrl,
    required this.title,
    required this.facultyName,
  });

  @override
  State<LiveVideoEmbedScreen> createState() => _LiveVideoEmbedScreenState();
}

class _LiveVideoEmbedScreenState extends State<LiveVideoEmbedScreen> {
  late final WebViewController _controller;

  String _getEmbedUrl(String url) {
    final u = url.trim();
    // YouTube watch URL -> embed
    final uri = Uri.tryParse(u);
    if (uri == null) return u;

    // youtu.be short links
    if (uri.host.contains('youtu.be')) {
      final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
      if (id.isNotEmpty) return 'https://www.youtube.com/embed/$id?autoplay=1';
    }

    // youtube.com watch?v=
    if (uri.host.contains('youtube.com')) {
      final vid = uri.queryParameters['v'];
      if (vid != null && vid.isNotEmpty) {
        return 'https://www.youtube.com/embed/$vid?autoplay=1';
      }
      // playlist or direct embed links
      if (uri.path.contains('/embed/')) return u;
    }

    // For other providers return original URL
    return u;
  }

  @override
  void initState() {
    super.initState();
    final embed = _getEmbedUrl(widget.streamUrl);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..loadRequest(Uri.parse(embed));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (widget.facultyName.isNotEmpty)
              Text(
                widget.facultyName,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
        backgroundColor: const Color(0xFF0D2240),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(child: WebViewWidget(controller: _controller)),
    );
  }
}
