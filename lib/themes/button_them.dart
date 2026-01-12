import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:restaurant/themes/app_them_data.dart';
import 'package:restaurant/themes/responsive.dart';
import 'package:restaurant/utils/dark_theme_provider.dart';

class ButtonThem {
  const ButtonThem({Key? key});

  static Widget buildButton(
    BuildContext context, {
    required String title,
    double btnHeight = 48,
    double txtSize = 14,
    double btnWidthRatio = 0.9,
    double btnRadius = 6,
    required VoidCallback? onPress,
    bool isVisible = true,
    bool isLoading = false,
  }) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    return Visibility(
      visible: isVisible,
      child: SizedBox(
        width: Responsive.width(100, context) * btnWidthRatio,
        child: MaterialButton(
          onPressed: isLoading ? null : onPress,
          height: btnHeight,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(btnRadius),
          ),
          color: AppThemeData.primary300,
          disabledColor: AppThemeData.primary300.withOpacity(0.6),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  title.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: txtSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  static Widget buildBorderButton(
    BuildContext context, {
    required String title,
    double btnHeight = 48,
    double txtSize = 14,
    double btnWidthRatio = 0.9,
    double borderRadius = 6,
    required VoidCallback onPress,
    bool isVisible = true,
    bool iconVisibility = false,
    String iconAssetImage = '',
  }) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    return Visibility(
      visible: isVisible,
      child: SizedBox(
        width: Responsive.width(100, context) * btnWidthRatio,
        height: btnHeight,
        child: ElevatedButton(
          onPressed: onPress,
          style: ButtonStyle(
            elevation: MaterialStateProperty.all(0),
            backgroundColor: MaterialStateProperty.all(
              isDark ? Colors.transparent : AppThemeData.surface,
            ),
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                side: BorderSide(
                  color: AppThemeData.primary300,
                  width: 1.2,
                ),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (iconVisibility)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Image.asset(
                    iconAssetImage,
                    width: 28,
                  ),
                ),
              Text(
                title.toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: txtSize,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppThemeData.grey100 : AppThemeData.grey900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget roundButton(
    BuildContext context, {
    required String title,
    required Color btnColor,
    required Color txtColor,
    double btnHeight = 48,
    double txtSize = 14,
    double btnWidthRatio = 0.9,
    required VoidCallback onPress,
    bool isVisible = true,
  }) {
    return Visibility(
      visible: isVisible,
      child: SizedBox(
        width: Responsive.width(100, context) * btnWidthRatio,
        child: MaterialButton(
          onPressed: onPress,
          height: btnHeight,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          color: btnColor,
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.poppins(
              color: txtColor,
              fontSize: txtSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
