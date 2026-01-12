import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:restaurant/themes/app_them_data.dart';
import 'package:restaurant/utils/dark_theme_provider.dart';

class TextFieldThem {
  const TextFieldThem({Key? key});

  static Widget buildTextFiled(
    BuildContext context, {
    required String hintText,
    required TextEditingController controller,
    TextInputType keyBoardType = TextInputType.text,
    bool enable = true,
    bool readOnly = false,
    int maxLine = 1,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    return TextFormField(
      controller: controller,
      enabled: enable,
      readOnly: readOnly,
      keyboardType: keyBoardType,
      maxLines: maxLine,
      inputFormatters: inputFormatters,
      style: GoogleFonts.poppins(
        color: isDark ? AppThemeData.grey100 : AppThemeData.grey900,
      ),
      decoration: _inputDecoration(
        isDark: isDark,
        hintText: hintText,
        maxLine: maxLine,
      ),
    );
  }

  static Widget buildTextFiledWithPrefixIcon(
    BuildContext context, {
    required String hintText,
    required TextEditingController controller,
    required Widget prefix,
    TextInputType keyBoardType = TextInputType.text,
    bool enable = true,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    return TextFormField(
      controller: controller,
      enabled: enable,
      keyboardType: keyBoardType,
      inputFormatters: inputFormatters,
      style: GoogleFonts.poppins(
        color: isDark ? AppThemeData.grey100 : AppThemeData.grey900,
      ),
      decoration: _inputDecoration(
        isDark: isDark,
        hintText: hintText,
      ).copyWith(prefixIcon: prefix),
    );
  }

  static Widget buildTextFiledWithSuffixIcon(
    BuildContext context, {
    required String hintText,
    required TextEditingController controller,
    required Widget suffixIcon,
    TextInputType keyBoardType = TextInputType.text,
    bool enable = true,
  }) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    return TextFormField(
      controller: controller,
      enabled: enable,
      keyboardType: keyBoardType,
      style: GoogleFonts.poppins(
        color: isDark ? AppThemeData.grey100 : AppThemeData.grey900,
      ),
      decoration: _inputDecoration(
        isDark: isDark,
        hintText: hintText,
      ).copyWith(suffixIcon: suffixIcon),
    );
  }

  // 🔹 Common decoration
  static InputDecoration _inputDecoration({
    required bool isDark,
    required String hintText,
    int maxLine = 1,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.poppins(
        color: isDark ? AppThemeData.grey400 : AppThemeData.grey500,
      ),
      filled: true,
      fillColor: isDark ? AppThemeData.surfaceDark : AppThemeData.surface,
      contentPadding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: maxLine == 1 ? 0 : 12,
      ),
      border: _border(isDark),
      enabledBorder: _border(isDark),
      disabledBorder: _border(isDark),
      errorBorder: _border(isDark),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(
          color: AppThemeData.primary300,
          width: 1.2,
        ),
      ),
    );
  }

  static OutlineInputBorder _border(bool isDark) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: BorderSide(
        color: isDark ? AppThemeData.grey700 : AppThemeData.grey300,
        width: 1,
      ),
    );
  }
}
