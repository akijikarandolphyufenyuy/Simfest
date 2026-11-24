import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// Plays a video URL with the browser's native controls (Flutter Web).
class VideoPreview extends StatelessWidget {
  final String url;
  const VideoPreview({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: ColoredBox(
          color: Colors.black,
          child: HtmlElementView.fromTagName(
            key: ValueKey(url),
            tagName: 'video',
            onElementCreated: (element) {
              final v = element as web.HTMLVideoElement;
              v
                ..src = url
                ..controls = true
                ..playsInline = true
                ..preload = 'metadata'
                ..style.width = '100%'
                ..style.height = '100%'
                ..style.objectFit = 'contain'
                ..style.backgroundColor = 'black';
            },
          ),
        ),
      ),
    );
  }
}
