import 'package:flutter/material.dart';

class CashControlThemeData {
  static const Color primitivePrimary = Color(0xFF2E6DEB);
  static const Color primitivePrimaryHover = Color(0xFF2457C6);
  static const Color primitiveSurface = Color(0xFFF6F8FF);
  static const Color primitiveBackground = Color(0xFFFFFFFF);
  static const Color primitiveTextPrimary = Color(0xFF101828);
  static const Color primitiveTextSecondary = Color(0xFF475467);
  static const Color primitiveSuccess = Color(0xFF027A48);
  static const Color primitiveError = Color(0xFFB42318);
  static const Color primitiveWarning = Color(0xFFB54708);
  static const Color primitiveInfo = Color(0xFF175CD3);
  static const Color primitiveBorder = Color(0xFFE3E8F0);
  static const Color primitiveMuted = Color(0xFFF2F4F7);

  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 12;
  static const double spacingLg = 16;
  static const double spacingXl = 24;
  static const double spacingXxl = 32;

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;

  static const double fontSizeBody = 14;
  static const double fontSizeBodyLarge = 16;
  static const double fontSizeTitle = 20;
  static const double fontSizeTitleLarge = 24;

  static const MaterialColor primarySwatch = MaterialColor(
    0xFF2E6DEB,
    <int, Color>{
      50: Color(0xFFEAF1FF),
      100: Color(0xFFD9E5FF),
      200: Color(0xFFB7CCFF),
      300: Color(0xFF8DAEFF),
      400: Color(0xFF5F8DFF),
      500: Color(0xFF2E6DEB),
      600: Color(0xFF2457C6),
      700: Color(0xFF1D469E),
      800: Color(0xFF173A83),
      900: Color(0xFF122F67),
    },
  );

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      primarySwatch: primarySwatch,
      scaffoldBackgroundColor: primitiveSurface,
      colorScheme: const ColorScheme.light(
        primary: primitivePrimary,
        onPrimary: Color(0xFFFFFFFF),
        secondary: primitiveInfo,
        onSecondary: Color(0xFFFFFFFF),
        surface: primitiveBackground,
        onSurface: primitiveTextPrimary,
        error: primitiveError,
        onError: Color(0xFFFFFFFF),
        tertiary: primitiveSuccess,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: fontSizeTitleLarge,
          fontWeight: FontWeight.w700,
          color: primitiveTextPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: fontSizeTitle,
          fontWeight: FontWeight.w700,
          color: primitiveTextPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: fontSizeBodyLarge,
          fontWeight: FontWeight.w400,
          color: primitiveTextPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: fontSizeBody,
          fontWeight: FontWeight.w400,
          color: primitiveTextPrimary,
        ),
        labelLarge: TextStyle(
          fontSize: fontSizeBodyLarge,
          fontWeight: FontWeight.w600,
          color: primitiveTextPrimary,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primitiveBackground,
        foregroundColor: primitiveTextPrimary,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: primitiveBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: primitiveBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: primitiveBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primitiveBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primitiveBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primitivePrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primitiveError, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: spacingLg, vertical: spacingMd),
      ),
    );

    return base.copyWith(
      extensions: <ThemeExtension<dynamic>>[
        CashControlColors(
          primary: primitivePrimary,
          primaryHover: primitivePrimaryHover,
          surface: primitiveSurface,
          background: primitiveBackground,
          textPrimary: primitiveTextPrimary,
          textSecondary: primitiveTextSecondary,
          success: primitiveSuccess,
          error: primitiveError,
          warning: primitiveWarning,
          info: primitiveInfo,
          border: primitiveBorder,
          muted: primitiveMuted,
          onPrimary: const Color(0xFFFFFFFF),
          onError: const Color(0xFFFFFFFF),
          onSuccess: const Color(0xFFFFFFFF),
          radiusSm: radiusSm,
          radiusMd: radiusMd,
          radiusLg: radiusLg,
          radiusXl: radiusXl,
          spacingXs: spacingXs,
          spacingSm: spacingSm,
          spacingMd: spacingMd,
          spacingLg: spacingLg,
          spacingXl: spacingXl,
          spacingXxl: spacingXxl,
          textBody: fontSizeBody,
          textBodyLarge: fontSizeBodyLarge,
          textTitle: fontSizeTitle,
          textTitleLarge: fontSizeTitleLarge,
        ),
      ],
    );
  }
}

class CashControlColors extends ThemeExtension<CashControlColors> {
  const CashControlColors({
    required this.primary,
    required this.primaryHover,
    required this.surface,
    required this.background,
    required this.textPrimary,
    required this.textSecondary,
    required this.success,
    required this.error,
    required this.warning,
    required this.info,
    required this.border,
    required this.muted,
    required this.onPrimary,
    required this.onError,
    required this.onSuccess,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
    required this.radiusXl,
    required this.spacingXs,
    required this.spacingSm,
    required this.spacingMd,
    required this.spacingLg,
    required this.spacingXl,
    required this.spacingXxl,
    required this.textBody,
    required this.textBodyLarge,
    required this.textTitle,
    required this.textTitleLarge,
  });

  final Color primary;
  final Color primaryHover;
  final Color surface;
  final Color background;
  final Color textPrimary;
  final Color textSecondary;
  final Color success;
  final Color error;
  final Color warning;
  final Color info;
  final Color border;
  final Color muted;
  final Color onPrimary;
  final Color onError;
  final Color onSuccess;
  final double radiusSm;
  final double radiusMd;
  final double radiusLg;
  final double radiusXl;
  final double spacingXs;
  final double spacingSm;
  final double spacingMd;
  final double spacingLg;
  final double spacingXl;
  final double spacingXxl;
  final double textBody;
  final double textBodyLarge;
  final double textTitle;
  final double textTitleLarge;

  @override
  ThemeExtension<CashControlColors> copyWith({
    Color? primary,
    Color? primaryHover,
    Color? surface,
    Color? background,
    Color? textPrimary,
    Color? textSecondary,
    Color? success,
    Color? error,
    Color? warning,
    Color? info,
    Color? border,
    Color? muted,
    Color? onPrimary,
    Color? onError,
    Color? onSuccess,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
    double? radiusXl,
    double? spacingXs,
    double? spacingSm,
    double? spacingMd,
    double? spacingLg,
    double? spacingXl,
    double? spacingXxl,
    double? textBody,
    double? textBodyLarge,
    double? textTitle,
    double? textTitleLarge,
  }) {
    return CashControlColors(
      primary: primary ?? this.primary,
      primaryHover: primaryHover ?? this.primaryHover,
      surface: surface ?? this.surface,
      background: background ?? this.background,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      success: success ?? this.success,
      error: error ?? this.error,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      border: border ?? this.border,
      muted: muted ?? this.muted,
      onPrimary: onPrimary ?? this.onPrimary,
      onError: onError ?? this.onError,
      onSuccess: onSuccess ?? this.onSuccess,
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusLg: radiusLg ?? this.radiusLg,
      radiusXl: radiusXl ?? this.radiusXl,
      spacingXs: spacingXs ?? this.spacingXs,
      spacingSm: spacingSm ?? this.spacingSm,
      spacingMd: spacingMd ?? this.spacingMd,
      spacingLg: spacingLg ?? this.spacingLg,
      spacingXl: spacingXl ?? this.spacingXl,
      spacingXxl: spacingXxl ?? this.spacingXxl,
      textBody: textBody ?? this.textBody,
      textBodyLarge: textBodyLarge ?? this.textBodyLarge,
      textTitle: textTitle ?? this.textTitle,
      textTitleLarge: textTitleLarge ?? this.textTitleLarge,
    );
  }

  @override
  ThemeExtension<CashControlColors> lerp(ThemeExtension<CashControlColors>? other, double t) {
    if (other is! CashControlColors) {
      return this;
    }
    return CashControlColors(
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      primaryHover: Color.lerp(primaryHover, other.primaryHover, t) ?? primaryHover,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      background: Color.lerp(background, other.background, t) ?? background,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      success: Color.lerp(success, other.success, t) ?? success,
      error: Color.lerp(error, other.error, t) ?? error,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      info: Color.lerp(info, other.info, t) ?? info,
      border: Color.lerp(border, other.border, t) ?? border,
      muted: Color.lerp(muted, other.muted, t) ?? muted,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t) ?? onPrimary,
      onError: Color.lerp(onError, other.onError, t) ?? onError,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t) ?? onSuccess,
      radiusSm: _lerpDouble(radiusSm, other.radiusSm, t),
      radiusMd: _lerpDouble(radiusMd, other.radiusMd, t),
      radiusLg: _lerpDouble(radiusLg, other.radiusLg, t),
      radiusXl: _lerpDouble(radiusXl, other.radiusXl, t),
      spacingXs: _lerpDouble(spacingXs, other.spacingXs, t),
      spacingSm: _lerpDouble(spacingSm, other.spacingSm, t),
      spacingMd: _lerpDouble(spacingMd, other.spacingMd, t),
      spacingLg: _lerpDouble(spacingLg, other.spacingLg, t),
      spacingXl: _lerpDouble(spacingXl, other.spacingXl, t),
      spacingXxl: _lerpDouble(spacingXxl, other.spacingXxl, t),
      textBody: _lerpDouble(textBody, other.textBody, t),
      textBodyLarge: _lerpDouble(textBodyLarge, other.textBodyLarge, t),
      textTitle: _lerpDouble(textTitle, other.textTitle, t),
      textTitleLarge: _lerpDouble(textTitleLarge, other.textTitleLarge, t),
    );
  }

  static double _lerpDouble(double a, double b, double t) => a + (b - a) * t;
}
