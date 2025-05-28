import 'package:flutter/material.dart';

import '../../../utils/constants/app_colors.dart';

class SocialSignInButton extends StatelessWidget {
  final String icon;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final double size;

  const SocialSignInButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.backgroundColor = AppColors.containerBackground,
    this.size = 50,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(size / 4),
        child: Image.asset(
          icon,
          width: size / 2,
          height: size / 2,
        ),
      ),
    );
  }
}
