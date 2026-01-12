import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A custom interactive rating star widget that uses SVG icons.
/// Uses ic_star.svg for active (filled) stars and ic_rate.svg for inactive (empty) stars.
class RatingStarWidget extends StatefulWidget {
  /// Initial rating value (0.0 to itemCount)
  final double initialRating;

  /// Number of stars to display
  final int itemCount;

  /// Size of each star
  final double itemSize;

  /// Padding between stars
  final EdgeInsets itemPadding;

  /// Callback when rating changes
  final ValueChanged<double> onRatingUpdate;

  /// Whether to allow half ratings (not implemented, for future use)
  final bool allowHalfRating;

  /// Whether to ignore user gestures (read-only mode)
  final bool ignoreGestures;

  /// Optional color filter for active stars
  final Color? activeColor;

  /// Optional color filter for inactive stars
  final Color? inactiveColor;

  const RatingStarWidget({
    super.key,
    this.initialRating = 0.0,
    this.itemCount = 5,
    this.itemSize = 24,
    this.itemPadding = const EdgeInsets.symmetric(horizontal: 4.0),
    required this.onRatingUpdate,
    this.allowHalfRating = false,
    this.ignoreGestures = false,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  State<RatingStarWidget> createState() => _RatingStarWidgetState();
}

class _RatingStarWidgetState extends State<RatingStarWidget> {
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  void didUpdateWidget(RatingStarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRating != widget.initialRating) {
      _currentRating = widget.initialRating;
    }
  }

  void _updateRating(int index) {
    if (widget.ignoreGestures) return;

    setState(() {
      _currentRating = index + 1.0;
    });
    widget.onRatingUpdate(_currentRating);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.itemCount, (index) {
        final isActive = index < _currentRating;

        return GestureDetector(
          onTap: () => _updateRating(index),
          child: Padding(
            padding: widget.itemPadding,
            child: SvgPicture.asset(
              isActive
                  ? 'assets/icons/ic_star.svg' // Active/filled star
                  : 'assets/icons/ic_rate.svg', // Inactive/empty star
              width: widget.itemSize,
              height: widget.itemSize,
              colorFilter: isActive && widget.activeColor != null
                  ? ColorFilter.mode(widget.activeColor!, BlendMode.srcIn)
                  : (!isActive && widget.inactiveColor != null
                      ? ColorFilter.mode(widget.inactiveColor!, BlendMode.srcIn)
                      : null),
            ),
          ),
        );
      }),
    );
  }
}

/// A read-only rating display widget using SVG icons.
/// Use this when you only need to display a rating without user interaction.
class RatingDisplayWidget extends StatelessWidget {
  /// The rating value to display
  final double rating;

  /// Number of stars to display
  final int itemCount;

  /// Size of each star
  final double itemSize;

  /// Padding between stars
  final EdgeInsets itemPadding;

  /// Optional color filter for active stars
  final Color? activeColor;

  /// Optional color filter for inactive stars
  final Color? inactiveColor;

  const RatingDisplayWidget({
    super.key,
    required this.rating,
    this.itemCount = 5,
    this.itemSize = 16,
    this.itemPadding = const EdgeInsets.symmetric(horizontal: 2.0),
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(itemCount, (index) {
        final isActive = index < rating;

        return Padding(
          padding: itemPadding,
          child: SvgPicture.asset(
            isActive
                ? 'assets/icons/ic_star.svg' // Active/filled star
                : 'assets/icons/ic_rate.svg', // Inactive/empty star
            width: itemSize,
            height: itemSize,
            colorFilter: isActive && activeColor != null
                ? ColorFilter.mode(activeColor!, BlendMode.srcIn)
                : (!isActive && inactiveColor != null
                    ? ColorFilter.mode(inactiveColor!, BlendMode.srcIn)
                    : null),
          ),
        );
      }),
    );
  }
}

/// A compact rating widget showing a single star with rating value.
/// Use this for displaying ratings in lists or cards.
class RatingBadgeWidget extends StatelessWidget {
  /// The rating value to display
  final double rating;

  /// Size of the star icon
  final double iconSize;

  /// Text style for the rating value
  final TextStyle? textStyle;

  /// Spacing between icon and text
  final double spacing;

  const RatingBadgeWidget({
    super.key,
    required this.rating,
    this.iconSize = 16,
    this.textStyle,
    this.spacing = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          'assets/icons/ic_star.svg',
          width: iconSize,
          height: iconSize,
        ),
        SizedBox(width: spacing),
        Text(
          rating.toStringAsFixed(1),
          style: textStyle ??
              const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

/*******************************************************************************************
* Copyright (c) 2025 Movenetics Digital. All rights reserved.
*
* This software and associated documentation files are the property of 
* Movenetics Digital. Unauthorized copying, modification, distribution, or use of this 
* Software, via any medium, is strictly prohibited without prior written permission.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
* INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
* PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE 
* LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT 
* OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR 
* OTHER DEALINGS IN THE SOFTWARE.
*
* Company: Movenetics Digital
* Author: Kasa Pogu Dharma Teja 
*******************************************************************************************/
