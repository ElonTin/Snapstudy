import 'package:flutter/material.dart';

/// Network avatar with decode size cap for memory efficiency.
class CachedNetworkAvatar extends StatelessWidget {
  const CachedNetworkAvatar({
    super.key,
    required this.radius,
    this.photoUrl,
    required this.initials,
    this.backgroundColor,
    this.foregroundColor,
  });

  final double radius;
  final String? photoUrl;
  final String initials;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final px = (radius * 2 * dpr).round();

    if (!hasPhoto) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        child: Text(
          initials,
          style: TextStyle(
            fontSize: radius * 0.72,
            color: foregroundColor,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: ClipOval(
        child: Image.network(
          photoUrl!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          cacheWidth: px,
          cacheHeight: px,
          filterQuality: FilterQuality.low,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => Text(
            initials,
            style: TextStyle(
              fontSize: radius * 0.72,
              color: foregroundColor,
            ),
          ),
        ),
      ),
    );
  }
}
