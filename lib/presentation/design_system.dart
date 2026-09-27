import 'package:flutter/material.dart';

/// Centralized Spacing Tokens
abstract final class AppSpace {
  static const xs = 4.0, s = 8.0, m = 12.0, l = 16.0, xl = 24.0, xxl = 32.0;
  static const formWidth = 640.0, contentWidth = 960.0, touch = 48.0;
}

/// Centralized Radii Tokens
abstract final class AppRadius {
  static const xs = 4.0, s = 8.0, m = 12.0, l = 16.0, xl = 24.0, pill = 999.0;
  static const borderRadiusXs = BorderRadius.all(Radius.circular(xs));
  static const borderRadiusS = BorderRadius.all(Radius.circular(s));
  static const borderRadiusM = BorderRadius.all(Radius.circular(m));
  static const borderRadiusL = BorderRadius.all(Radius.circular(l));
  static const borderRadiusPill = BorderRadius.all(Radius.circular(pill));
}

/// Centralized Palette & Semantic Tokens
abstract final class AppColors {
  static const primary = Color(0xFF244A73);
  static const primaryLight = Color(0xFFE8EEF5);
  static const primaryDark = Color(0xFF19324E);

  static const secondary = Color(0xFF526579);
  static const accentWarm = Color(0xFFC5A059);
  static const accentWarmLight = Color(0xFFFAF6F0);

  static const background = Color(0xFFF8FAF8);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF1F5F9);

  static const text = Color(0xFF17212B);
  static const secondaryText = Color(0xFF52606D);
  static const textMuted = Color(0xFF8292A2);

  static const border = Color(0xFFCBD2D9);
  static const borderSubtle = Color(0xFFE2E8F0);

  // Semantic States
  static const success = Color(0xFF23633B);
  static const successBg = Color(0xFFE8F5E9);
  static const successBorder = Color(0xFFA5D6A7);

  static const warning = Color(0xFF805500);
  static const warningBg = Color(0xFFFFF8E1);
  static const warningBorder = Color(0xFFFFE082);

  static const danger = Color(0xFFB3261E);
  static const dangerBg = Color(0xFFFFEBEE);
  static const dangerBorder = Color(0xFFEF9A9A);

  static const info = Color(0xFF1976D2);
  static const infoBg = Color(0xFFE3F2FD);
  static const infoBorder = Color(0xFF90CAF9);
}

/// Centralized Theme Generator
abstract final class AppTheme {
  static const primary = AppColors.primary;
  static const secondary = AppColors.secondary;
  static const background = AppColors.background;
  static const surface = AppColors.surface;
  static const text = AppColors.text;
  static const secondaryText = AppColors.secondaryText;
  static const border = AppColors.border;
  static const success = AppColors.success;
  static const warning = AppColors.warning;
  static const error = AppColors.danger;

  static ThemeData theme(Brightness brightness) {
    var scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    );
    if (brightness == Brightness.light) {
      scheme = scheme.copyWith(
        primary: primary,
        onPrimary: surface,
        secondary: secondary,
        surface: surface,
        onSurface: text,
        onSurfaceVariant: secondaryText,
        outlineVariant: border,
        error: error,
      );
    }
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: brightness == Brightness.light
          ? background
          : scheme.surface,
      visualDensity: VisualDensity.standard,
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          fontSize: 24,
          height: 32 / 24,
          fontWeight: FontWeight.w600,
          color: text,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          height: 28 / 20,
          fontWeight: FontWeight.w600,
          color: text,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          height: 24 / 16,
          fontWeight: FontWeight.w600,
          color: text,
        ),
        bodyLarge: TextStyle(fontSize: 16, height: 24 / 16, color: text),
        bodyMedium: TextStyle(fontSize: 14, height: 20 / 14, color: text),
        bodySmall: TextStyle(
          fontSize: 12,
          height: 18 / 12,
          color: secondaryText,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          height: 20 / 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      dialogTheme: DialogThemeData(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusL),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: AppRadius.borderRadiusS,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderRadiusS,
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderRadiusS,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpace.l,
          vertical: AppSpace.m,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(AppSpace.touch, AppSpace.touch),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusS),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.surface,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(AppSpace.touch, AppSpace.touch),
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusS),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderRadiusM,
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
      ),
    );
  }
}

/// Bidirectional Text Isolation Helper
abstract final class BidiTextFormatter {
  static String isolate(String text) => '\u2068$text\u2069';
}

// ============================================================================
// SHARED DESIGN SYSTEM PRIMITIVES & COMPONENTS
// ============================================================================

/// Reusable Standard Card Component
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.l),
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.onTap,
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? AppRadius.borderRadiusM;
    final borderSide = BorderSide(
      color: borderColor ?? AppColors.borderSubtle,
      width: 1,
    );

    Widget content = Padding(padding: padding, child: child);

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: effectiveRadius,
        child: content,
      );
    }

    Widget cardMaterial = Material(
      color: backgroundColor ?? AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: effectiveRadius,
        side: borderSide,
      ),
      clipBehavior: Clip.antiAlias,
      child: content,
    );

    if (margin != null) {
      cardMaterial = Padding(padding: margin!, child: cardMaterial);
    }

    return cardMaterial;
  }
}

/// Reusable Compact Screen Banner / Metric Hero Banner
class AppScreenBanner extends StatelessWidget {
  const AppScreenBanner({
    super.key,
    required this.title,
    this.subtitle,
    this.metrics = const [],
    this.action,
    this.icon = Icons.folder_shared_outlined,
  });

  final String title;
  final String? subtitle;
  final List<AppBannerMetric> metrics;
  final Widget? action;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: AppRadius.borderRadiusM,
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F244A73),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpace.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpace.s),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.15),
                  borderRadius: AppRadius.borderRadiusS,
                ),
                child: Icon(icon, color: AppColors.surface, size: 22),
              ),
              const SizedBox(width: AppSpace.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.surface,
                        height: 1.2,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.surface.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ?action,
            ],
          ),
          if (metrics.isNotEmpty) ...[
            const SizedBox(height: AppSpace.m),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: AppSpace.m),
            Wrap(
              spacing: AppSpace.m,
              runSpacing: AppSpace.s,
              children: metrics.map((m) => _buildMetricItem(m)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricItem(AppBannerMetric m) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.m,
        vertical: AppSpace.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.12),
        borderRadius: AppRadius.borderRadiusPill,
        border: Border.all(color: AppColors.surface.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (m.icon != null) ...[
            Icon(m.icon, size: 14, color: AppColors.surface),
            const SizedBox(width: AppSpace.xs),
          ],
          Text(
            m.label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.surface.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(width: AppSpace.xs),
          Text(
            m.value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.surface,
            ),
          ),
        ],
      ),
    );
  }
}

/// Data item model for AppScreenBanner metrics
class AppBannerMetric {
  const AppBannerMetric({required this.label, required this.value, this.icon});

  final String label;
  final String value;
  final IconData? icon;
}

/// Reusable Semantic Status Chip / Badge
enum AppStatusType { active, inactive, deleted, warning, danger, info, neutral }

class AppStatusChip extends StatelessWidget {
  const AppStatusChip({
    super.key,
    required this.label,
    this.type = AppStatusType.neutral,
    this.icon,
    this.showDot = true,
  });

  final String label;
  final AppStatusType type;
  final IconData? icon;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final colors = _getColors(type);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.s + 2,
        vertical: AppSpace.xs,
      ),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: AppRadius.borderRadiusPill,
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: colors.text),
            const SizedBox(width: AppSpace.xs),
          ] else if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: colors.text,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpace.xs),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.text,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  _StatusColors _getColors(AppStatusType type) {
    switch (type) {
      case AppStatusType.active:
        return const _StatusColors(
          bg: AppColors.successBg,
          text: AppColors.success,
          border: AppColors.successBorder,
        );
      case AppStatusType.inactive:
        return const _StatusColors(
          bg: AppColors.surfaceMuted,
          text: AppColors.secondaryText,
          border: AppColors.borderSubtle,
        );
      case AppStatusType.deleted:
      case AppStatusType.danger:
        return const _StatusColors(
          bg: AppColors.dangerBg,
          text: AppColors.danger,
          border: AppColors.dangerBorder,
        );
      case AppStatusType.warning:
        return const _StatusColors(
          bg: AppColors.warningBg,
          text: AppColors.warning,
          border: AppColors.warningBorder,
        );
      case AppStatusType.info:
        return const _StatusColors(
          bg: AppColors.infoBg,
          text: AppColors.info,
          border: AppColors.infoBorder,
        );
      case AppStatusType.neutral:
        return const _StatusColors(
          bg: AppColors.primaryLight,
          text: AppColors.primary,
          border: AppColors.borderSubtle,
        );
    }
  }
}

class _StatusColors {
  const _StatusColors({
    required this.bg,
    required this.text,
    required this.border,
  });
  final Color bg;
  final Color text;
  final Color border;
}

/// Reusable Operational Alert Banner (Offline, Reconnecting, Read-Only, Error)
class AppBannerAlert extends StatelessWidget {
  const AppBannerAlert({
    super.key,
    required this.message,
    this.type = AppStatusType.warning,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final AppStatusType type;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = _getColors(type);
    final effectiveIcon = icon ?? _getDefaultIcon(type);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.m),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.m,
        vertical: AppSpace.s + 2,
      ),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: AppRadius.borderRadiusS,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(effectiveIcon, color: colors.text, size: 18),
          const SizedBox(width: AppSpace.m),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colors.text,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: AppSpace.s),
            InkWell(
              onTap: onAction,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.xs,
                  vertical: 2,
                ),
                child: Text(
                  actionLabel!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: colors.text,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getDefaultIcon(AppStatusType type) {
    switch (type) {
      case AppStatusType.warning:
        return Icons.warning_amber_rounded;
      case AppStatusType.danger:
      case AppStatusType.deleted:
        return Icons.error_outline;
      case AppStatusType.info:
      case AppStatusType.neutral:
        return Icons.info_outline;
      case AppStatusType.active:
        return Icons.check_circle_outline;
      case AppStatusType.inactive:
        return Icons.pause_circle_outline;
    }
  }

  _StatusColors _getColors(AppStatusType type) {
    switch (type) {
      case AppStatusType.warning:
        return const _StatusColors(
          bg: AppColors.warningBg,
          text: AppColors.warning,
          border: AppColors.warningBorder,
        );
      case AppStatusType.danger:
      case AppStatusType.deleted:
        return const _StatusColors(
          bg: AppColors.dangerBg,
          text: AppColors.danger,
          border: AppColors.dangerBorder,
        );
      case AppStatusType.info:
        return const _StatusColors(
          bg: AppColors.infoBg,
          text: AppColors.info,
          border: AppColors.infoBorder,
        );
      case AppStatusType.active:
        return const _StatusColors(
          bg: AppColors.successBg,
          text: AppColors.success,
          border: AppColors.successBorder,
        );
      default:
        return const _StatusColors(
          bg: AppColors.surfaceMuted,
          text: AppColors.secondaryText,
          border: AppColors.borderSubtle,
        );
    }
  }
}

/// Reusable Section Header
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.badgeText,
    this.action,
  });

  final String title;
  final String? subtitle;
  final String? badgeText;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                if (badgeText != null) ...[
                  const SizedBox(width: AppSpace.s),
                  AppStatusChip(
                    label: badgeText!,
                    type: AppStatusType.neutral,
                    showDot: false,
                  ),
                ],
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// Reusable Empty State View
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpace.l),
              decoration: const BoxDecoration(
                color: AppColors.surfaceMuted,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.secondaryText),
            ),
            const SizedBox(height: AppSpace.m),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.secondaryText,
                height: 1.4,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpace.l),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add, size: 18),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Reusable Operational List Item Row
class AppListRow extends StatelessWidget {
  const AppListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon = Icons.person_outline,
    this.statusChip,
    this.onTap,
    this.isDeleted = false,
  });

  final String title;
  final String? subtitle;
  final IconData leadingIcon;
  final Widget? statusChip;
  final VoidCallback? onTap;
  final bool isDeleted;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpace.s),
      padding: const EdgeInsets.all(AppSpace.m),
      onTap: onTap,
      backgroundColor: isDeleted ? AppColors.surfaceMuted : AppColors.surface,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDeleted
                  ? AppColors.borderSubtle
                  : AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              leadingIcon,
              color: isDeleted ? AppColors.secondaryText : AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpace.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDeleted
                              ? AppColors.secondaryText
                              : AppColors.text,
                          decoration: isDeleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                    if (statusChip != null) ...[
                      const SizedBox(width: AppSpace.s),
                      statusChip!,
                    ],
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpace.s),
          const Icon(Icons.chevron_right, color: AppColors.border, size: 20),
        ],
      ),
    );
  }
}
