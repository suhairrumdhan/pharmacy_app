import 'package:flutter/material.dart';

class MedicinesTableStyle {
  // Colors
  static const Color primaryColor = Color(0xFF1A73E8);
  static const Color secondaryColor = Color(0xFF34A853);
  static const Color warningColor = Color(0xFFFB8C00);
  static const Color dangerColor = Color(0xFFEA4335);
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color darkText = Color(0xFF202124);
  static const Color mediumText = Color(0xFF5F6368);
  static const Color lightText = Color(0xFF9AA0A6);
  static const Color borderColor = Color(0xFFDADCE0);

  // Gradients
  static LinearGradient get headerGradient => LinearGradient(
    colors: [
      Color(0xFF1A73E8),
      Color(0xFF42dff4),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get loadingGradient => LinearGradient(
    colors: [
      Color(0xFFE8F0FE),
      Color(0xFFF3E5F5),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get emptyStateGradient => LinearGradient(
    colors: [
      Color(0xFFF1F3F4),
      Color(0xFFE8EAED),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get tableGradient => LinearGradient(
    colors: [
      Colors.white,
      Color(0xFFF8F9FA),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Text Styles
  static TextStyle get headerText => TextStyle(
    color: Colors.white,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  static TextStyle get medicineNameText => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: darkText,
    letterSpacing: -0.2,
  );

  static TextStyle get scientificNameText => TextStyle(
    fontSize: 16,
    color: mediumText,
    fontWeight: FontWeight.w500,
  );

  static TextStyle get categoryText => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get priceText => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: Color(0xFF0D652D),
  );

  static TextStyle get stockText => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );

  static TextStyle get supplierText => TextStyle(
    fontSize: 14,
    color: mediumText,
    fontWeight: FontWeight.w500,
  );

  static TextStyle get expiryText => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get statusText => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get footerText => TextStyle(
    fontSize: 12,
    color: mediumText,
  );

  // Shadows
  static List<BoxShadow> get tableShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 20,
      spreadRadius: 2,
      offset: Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get medicineIconShadow => [
    BoxShadow(
      color: primaryColor.withOpacity(0.3),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  // Border Radius
  static BorderRadius get tableBorderRadius => BorderRadius.circular(16);
  static BorderRadius get headerBorderRadius => BorderRadius.only(
    topLeft: Radius.circular(16),
    topRight: Radius.circular(16),
  );
  static BorderRadius get footerBorderRadius => BorderRadius.only(
    bottomLeft: Radius.circular(16),
    bottomRight: Radius.circular(16),
  );
  static BorderRadius get buttonBorderRadius => BorderRadius.circular(12);
  static BorderRadius get cardBorderRadius => BorderRadius.circular(10);
  static BorderRadius get badgeBorderRadius => BorderRadius.circular(20);
  static BorderRadius get chipBorderRadius => BorderRadius.circular(6);

  // Paddings
  static EdgeInsets get tablePadding => EdgeInsets.all(0);
  static EdgeInsets get rowPadding => EdgeInsets.symmetric(vertical: 16, horizontal: 16);
  static EdgeInsets get headerPadding => EdgeInsets.symmetric(vertical: 18, horizontal: 16);
  static EdgeInsets get footerPadding => EdgeInsets.symmetric(vertical: 16, horizontal: 20);
  static EdgeInsets get cellPadding => EdgeInsets.symmetric(horizontal: 12, vertical: 6);
  static EdgeInsets get actionButtonPadding => EdgeInsets.symmetric(horizontal: 2);
  static EdgeInsets get statItemPadding => EdgeInsets.symmetric(horizontal: 12, vertical: 6);

  // Sizes
  static double get medicineIconSize => 50;
  static double get headerIconSize => 24;
  static double get actionIconSize => 16;
  static double get statIconSize => 20;
  static double get stockCircleSize => 40;
  static double get actionButtonSize => 36;
}