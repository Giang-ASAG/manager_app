import 'package:flutter/material.dart';

/// Responsive utility — scale font, spacing, size theo màn hình.
///
/// Baseline: 390 × 844 (iPhone 14)
///
/// Cách dùng (extension trên BuildContext):
///   context.sp(16)   → font size
///   context.w(24)    → horizontal spacing / width
///   context.h(48)    → vertical spacing / height
///   context.r(12)    → border radius
///
/// Hoặc dùng static:
///   AppResponsive.of(context).sp(16)
class AppResponsive {
  static const double _baseWidth = 390.0;
  static const double _baseHeight = 844.0;

  /// Tablet breakpoint
  static const double _tabletBreakpoint = 600.0;

  final double _screenWidth;
  final double _screenHeight;
  final double _scaleW;
  final double _scaleH;
  final bool _isTablet;

  AppResponsive._({
    required double screenWidth,
    required double screenHeight,
  })  : _screenWidth = screenWidth,
        _screenHeight = screenHeight,
        _scaleW = screenWidth / _baseWidth,
        _scaleH = screenHeight / _baseHeight,
        _isTablet = screenWidth >= _tabletBreakpoint;

  factory AppResponsive.of(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AppResponsive._(
      screenWidth: size.width,
      screenHeight: size.height,
    );
  }

  bool get isTablet => _isTablet;
  double get screenWidth => _screenWidth;
  double get screenHeight => _screenHeight;

  /// Font size — scale theo chiều rộng, giới hạn tối đa 1.4x để tablet không
  /// quá to.
  double sp(double size) {
    final scale = _scaleW.clamp(0.8, 1.4);
    return size * scale;
  }

  /// Width-based value (padding ngang, icon width, container width...)
  double w(double size) {
    return size * _scaleW.clamp(0.85, 1.5);
  }

  /// Height-based value (padding dọc, icon height, button height...)
  double h(double size) {
    return size * _scaleH.clamp(0.85, 1.4);
  }

  /// Border radius — scale nhẹ hơn để không quá tròn trên tablet
  double r(double radius) {
    return radius * _scaleW.clamp(0.85, 1.25);
  }

  /// Grid column count — phone: default, tablet: nhiều hơn
  int adaptiveCrossAxisCount({
    required int phone,
    required int tablet,
  }) {
    return _isTablet ? tablet : phone;
  }
}

/// Extension tiện lợi — dùng trực tiếp từ context
extension ResponsiveContext on BuildContext {
  AppResponsive get _r => AppResponsive.of(this);

  double sp(double size) => _r.sp(size);
  double rw(double size) => _r.w(size);
  double rh(double size) => _r.h(size);
  double rr(double radius) => _r.r(radius);
  bool get isTablet => _r.isTablet;
}
