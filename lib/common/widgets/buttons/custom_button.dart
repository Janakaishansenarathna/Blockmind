import 'package:flutter/material.dart';
import '../../../utils/constants/app_colors.dart';

enum ButtonVariant { filled, outline, text }

class CustomButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String? text;
  final Widget? child;
  final double? width;
  final double height;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isLoading;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry padding;
  final double elevation;
  final ButtonVariant variant;

  const CustomButton({
    super.key,
    this.onPressed,
    this.text,
    this.child,
    this.width,
    this.height = 56,
    this.backgroundColor,
    this.foregroundColor,
    this.isLoading = false,
    this.borderRadius,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    this.elevation = 0,
    this.variant = ButtonVariant.filled,
  }) : assert(text != null || child != null,
            'Either text or child must be provided');

  @override
  Widget build(BuildContext context) {
    final buttonChild = child ??
        Text(
          text!,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        );

    switch (variant) {
      case ButtonVariant.filled:
        return _buildFilledButton(buttonChild);
      case ButtonVariant.outline:
        return _buildOutlineButton(buttonChild);
      case ButtonVariant.text:
        return _buildTextButton(buttonChild);
    }
  }

  Widget _buildFilledButton(Widget buttonChild) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.buttonPrimary,
          foregroundColor: foregroundColor ?? Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(12),
          ),
          elevation: elevation,
          padding: padding,
          disabledBackgroundColor:
              (backgroundColor ?? AppColors.buttonPrimary).withOpacity(0.6),
          disabledForegroundColor:
              (foregroundColor ?? Colors.white).withOpacity(0.6),
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      foregroundColor ?? Colors.white),
                ),
              )
            : buttonChild,
      ),
    );
  }

  Widget _buildOutlineButton(Widget buttonChild) {
    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: foregroundColor ?? AppColors.buttonPrimary,
          side: BorderSide(
            color: backgroundColor ?? AppColors.buttonPrimary,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(12),
          ),
          padding: padding,
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      foregroundColor ?? AppColors.buttonPrimary),
                ),
              )
            : buttonChild,
      ),
    );
  }

  Widget _buildTextButton(Widget buttonChild) {
    return SizedBox(
      width: width,
      height: height,
      child: TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: foregroundColor ?? AppColors.buttonPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(12),
          ),
          padding: padding,
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      foregroundColor ?? AppColors.buttonPrimary),
                ),
              )
            : buttonChild,
      ),
    );
  }
}

class CustomOutlinedButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final double? width;
  final double height;
  final Color borderColor;
  final Color textColor;
  final bool isLoading;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry padding;
  final double borderWidth;

  const CustomOutlinedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.width,
    this.height = 50,
    this.borderColor = AppColors.buttonPrimary,
    this.textColor = AppColors.buttonPrimary,
    this.isLoading = false,
    this.borderRadius,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    this.borderWidth = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          side: BorderSide(
            color: borderColor,
            width: borderWidth,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(12),
          ),
          padding: padding,
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            : child,
      ),
    );
  }
}

// Gradient Button for special cases
class CustomGradientButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final double? width;
  final double height;
  final Gradient gradient;
  final Color textColor;
  final bool isLoading;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry padding;

  const CustomGradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.width,
    this.height = 50,
    this.gradient = const LinearGradient(
      colors: [AppColors.buttonPrimary, Color(0xFF1A56DB)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
    this.textColor = AppColors.textPrimary,
    this.isLoading = false,
    this.borderRadius,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.buttonPrimary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          foregroundColor: textColor,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(12),
          ),
          padding: padding,
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            : child,
      ),
    );
  }
}
