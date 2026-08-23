import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';

/// Button variant types.
enum CustomButtonVariant { filled, outlined, text }

/// Reusable button widget with filled, outlined, and text variants.
///
/// Provides consistent styling across all screens. Use this instead
/// of inline button styling.
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final CustomButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final Widget? iconWidget;
  final double? width;
  final EdgeInsetsGeometry? padding;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = CustomButtonVariant.filled,
    this.isLoading = false,
    this.icon,
    this.iconWidget,
    this.width,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ??
        const EdgeInsets.symmetric(horizontal: 24, vertical: 16);

    switch (variant) {
      case CustomButtonVariant.filled:
        return SizedBox(
          width: width ?? double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              padding: effectivePadding,
              backgroundColor: AppColors.primaryDark,
              foregroundColor: AppColors.textOnPrimary,
              disabledBackgroundColor: AppColors.primaryDark.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusPill),
              ),
            ),
            child: _buildChild(AppColors.textOnPrimary),
          ),
        );
      case CustomButtonVariant.outlined:
        return SizedBox(
          width: width ?? double.infinity,
          child: OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              padding: effectivePadding,
              side: const BorderSide(color: AppColors.primaryDark, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusPill),
              ),
            ),
            child: _buildChild(AppColors.primaryDark),
          ),
        );
      case CustomButtonVariant.text:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            padding: effectivePadding,
          ),
          child: _buildChild(AppColors.primaryDark),
        );
    }
  }

  Widget _buildChild(Color color) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    final leadingIcon = iconWidget ??
        (icon != null
            ? Icon(icon, size: AppConstants.iconSizeMedium)
            : null);

    if (leadingIcon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          leadingIcon,
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }
}
