import 'package:flutter/material.dart';

import '../core/theme/cashcontrol_theme.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.enabled = true,
    this.variant = AppButtonVariant.primary,
    this.fullWidth = false,
  });

  final String label;
  final IconData? icon;
  final bool loading;
  final bool enabled;
  final AppButtonVariant variant;
  final bool fullWidth;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CashControlColors>()!;
    final style = switch (variant) {
      AppButtonVariant.primary => ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (!enabled || loading) return Colors.grey.shade300;
            return states.contains(WidgetState.pressed) ? colors.primaryHover : colors.primary;
          }),
          foregroundColor: WidgetStateProperty.all(colors.onPrimary),
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: colors.spacingLg, vertical: colors.spacingMd),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(colors.radiusMd)),
          ),
        ),
      AppButtonVariant.secondary => ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(colors.muted),
          foregroundColor: WidgetStatePropertyAll(colors.textPrimary),
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: colors.spacingLg, vertical: colors.spacingMd),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(colors.radiusMd)),
          ),
        ),
    };

    final child = loading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                variant == AppButtonVariant.primary ? colors.onPrimary : colors.textPrimary,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                SizedBox(width: colors.spacingSm),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          );

    return Semantics(
      button: true,
      enabled: enabled && !loading,
      label: label,
      child: SizedBox(
        width: fullWidth ? double.infinity : null,
        child: FilledButton(
          style: style,
          onPressed: enabled && !loading ? onPressed : null,
          child: child,
        ),
      ),
    );
  }
}

enum AppButtonVariant { primary, secondary }
