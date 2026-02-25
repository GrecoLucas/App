import 'package:flutter/material.dart';

class DefaultAvatarWidget extends StatelessWidget {
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;

  const DefaultAvatarWidget({
    super.key,
    this.size = 100,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? Colors.grey[200],
      ),
      child: Icon(
        Icons.person,
        size: size * 0.6,
        color: iconColor ?? Colors.grey[400],
      ),
    );
  }
}
