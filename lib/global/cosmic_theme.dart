import 'dart:ui';

import 'package:flutter/material.dart';

/// Cosmic Vinyl color palette constants for Robin Radio.
///
/// This theme creates a luxurious, deep space-inspired aesthetic
/// with rich purples, ethereal glows, and golden accents.
class CosmicColors {
  CosmicColors._();

  /// Deep space background - the darkest purple
  static const deepPurple = Color(0xFF1A0B2E);

  /// Rich royal purple for cards and containers
  static const royalPurple = Color(0xFF3D1A5C);

  /// Vibrant purple for primary actions and highlights
  static const vibrantPurple = Color(0xFF7B2CBF);

  /// Soft lavender for text and subtle glows
  static const lavenderGlow = Color(0xFFC8A2E8);

  /// Warm golden amber for accents and highlights
  static const goldenAmber = Color(0xFFE8B86D);

  /// Near-black purple for deepest backgrounds
  static const voidBlack = Color(0xFF0D0618);

  /// Cosmic gradient for main backgrounds
  static const cosmicGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [deepPurple, voidBlack],
  );

  /// Card gradient for glassmorphism containers
  static LinearGradient cardGradient({double opacity = 0.6}) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          royalPurple.withValues(alpha: opacity),
          deepPurple.withValues(alpha: opacity * 0.7),
        ],
      );

  /// Neon glow shadow for highlighted elements
  static List<BoxShadow> neonGlow({
    Color color = vibrantPurple,
    double intensity = 0.5,
  }) =>
      [
        BoxShadow(
          color: color.withValues(alpha: intensity),
          blurRadius: 20,
          spreadRadius: 2,
        ),
        BoxShadow(
          color: lavenderGlow.withValues(alpha: intensity * 0.4),
          blurRadius: 40,
          spreadRadius: 5,
        ),
      ];

  /// Subtle ambient glow for cards
  static List<BoxShadow> ambientGlow({double intensity = 0.3}) => [
        BoxShadow(
          color: vibrantPurple.withValues(alpha: intensity),
          blurRadius: 15,
          spreadRadius: 1,
        ),
      ];
}

/// Glassmorphism decoration helper for Cosmic Vinyl theme.
class CosmicGlass {
  CosmicGlass._();

  /// Standard blur amount for glassmorphism
  static ImageFilter get blur => ImageFilter.blur(sigmaX: 10, sigmaY: 10);

  /// Heavy blur for prominent glass elements
  static ImageFilter get heavyBlur => ImageFilter.blur(sigmaX: 15, sigmaY: 15);

  /// Decoration for glassmorphic containers
  static BoxDecoration decoration({
    double borderRadius = 16,
    double opacity = 0.6,
    bool showBorder = true,
  }) =>
      BoxDecoration(
        gradient: CosmicColors.cardGradient(opacity: opacity),
        borderRadius: BorderRadius.circular(borderRadius),
        border: showBorder
            ? Border.all(
                color: CosmicColors.lavenderGlow.withValues(alpha: 0.2),
              )
            : null,
        boxShadow: CosmicColors.ambientGlow(),
      );
}

/// A glassmorphic card widget with the Cosmic Vinyl aesthetic.
///
/// Provides a frosted glass effect with gradient backgrounds,
/// subtle borders, and ambient glow shadows.
class CosmicCard extends StatelessWidget {
  /// Creates a cosmic glassmorphic card.
  const CosmicCard({
    required this.child,
    super.key,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.opacity = 0.6,
    this.showBorder = true,
    this.enableBlur = true,
    this.onTap,
  });

  /// The widget to display inside the card.
  final Widget child;

  /// Padding inside the card.
  final EdgeInsetsGeometry? padding;

  /// Margin around the card.
  final EdgeInsetsGeometry? margin;

  /// Corner radius of the card.
  final double borderRadius;

  /// Opacity of the glassmorphism effect.
  final double opacity;

  /// Whether to show the subtle border.
  final bool showBorder;

  /// Whether to enable the blur effect.
  final bool enableBlur;

  /// Callback when the card is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      margin: margin,
      decoration: CosmicGlass.decoration(
        borderRadius: borderRadius,
        opacity: opacity,
        showBorder: showBorder,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: enableBlur
            ? BackdropFilter(
                filter: CosmicGlass.blur,
                child: Padding(
                  padding: padding ?? EdgeInsets.zero,
                  child: child,
                ),
              )
            : Padding(
                padding: padding ?? EdgeInsets.zero,
                child: child,
              ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }
    return content;
  }
}

/// A container that adds a neon glow effect around its child.
///
/// Creates the signature Cosmic Vinyl glowing effect that makes
/// elements appear to emit ethereal light.
class NeonGlowBox extends StatelessWidget {
  /// Creates a neon glow container.
  const NeonGlowBox({
    required this.child,
    super.key,
    this.color,
    this.intensity = 0.5,
    this.shape = BoxShape.rectangle,
    this.borderRadius,
  });

  /// The widget to wrap with the glow effect.
  final Widget child;

  /// The color of the glow. Defaults to vibrant purple.
  final Color? color;

  /// Intensity of the glow from 0.0 to 1.0.
  final double intensity;

  /// Shape of the glow container.
  final BoxShape shape;

  /// Border radius for rectangle shapes.
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          shape: shape,
          borderRadius: shape == BoxShape.rectangle ? borderRadius : null,
          boxShadow: CosmicColors.neonGlow(
            color: color ?? CosmicColors.vibrantPurple,
            intensity: intensity,
          ),
        ),
        child: child,
      );
}

/// A styled button with the Cosmic Vinyl neon glow aesthetic.
///
/// Features gradient background, subtle border, and glowing shadow
/// effects that respond to tap interactions.
class CosmicButton extends StatelessWidget {
  /// Creates a cosmic styled button.
  const CosmicButton({
    required this.onPressed,
    required this.child,
    super.key,
    this.padding,
    this.borderRadius = 12,
    this.enableGlow = true,
    this.glowIntensity = 0.4,
    this.backgroundColor,
  });

  /// Callback when the button is pressed.
  final VoidCallback? onPressed;

  /// The widget to display inside the button.
  final Widget child;

  /// Padding inside the button.
  final EdgeInsetsGeometry? padding;

  /// Corner radius of the button.
  final double borderRadius;

  /// Whether to show the neon glow effect.
  final bool enableGlow;

  /// Intensity of the glow effect.
  final double glowIntensity;

  /// Optional custom background color.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow:
              enableGlow ? CosmicColors.neonGlow(intensity: glowIntensity) : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(borderRadius),
            child: Container(
              padding:
                  padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: backgroundColor == null
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          CosmicColors.vibrantPurple,
                          CosmicColors.royalPurple,
                        ],
                      )
                    : null,
                color: backgroundColor,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: CosmicColors.lavenderGlow.withValues(alpha: 0.3),
                ),
              ),
              child: child,
            ),
          ),
        ),
      );
}

/// A styled text widget with optional glow effect for the Cosmic Vinyl theme.
///
/// Provides consistent text styling with the ability to add
/// ethereal glow shadows for emphasis.
class CosmicText extends StatelessWidget {
  /// Creates a cosmic styled text widget.
  const CosmicText(
    this.text, {
    super.key,
    this.style,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.enableGlow = false,
    this.glowColor,
    this.glowBlurRadius = 10,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  /// The text to display.
  final String text;

  /// Base text style to apply.
  final TextStyle? style;

  /// Text color. Defaults to lavender glow.
  final Color? color;

  /// Font size.
  final double? fontSize;

  /// Font weight.
  final FontWeight? fontWeight;

  /// Whether to add a glow effect behind the text.
  final bool enableGlow;

  /// Color of the glow effect. Defaults to vibrant purple.
  final Color? glowColor;

  /// Blur radius for the glow effect.
  final double glowBlurRadius;

  /// Text alignment.
  final TextAlign? textAlign;

  /// Maximum number of lines.
  final int? maxLines;

  /// Text overflow behavior.
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) => Text(
        text,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        style: (style ?? const TextStyle()).copyWith(
          color: color ?? CosmicColors.lavenderGlow,
          fontSize: fontSize,
          fontWeight: fontWeight,
          shadows: enableGlow
              ? [
                  Shadow(
                    color: (glowColor ?? CosmicColors.vibrantPurple)
                        .withValues(alpha: 0.8),
                    blurRadius: glowBlurRadius,
                  ),
                ]
              : null,
        ),
      );
}

/// A gradient background widget for the Cosmic Vinyl theme.
///
/// Provides the signature deep space gradient that forms the
/// foundation of all Cosmic Vinyl screens.
class CosmicBackground extends StatelessWidget {
  /// Creates a cosmic gradient background.
  const CosmicBackground({
    required this.child,
    super.key,
    this.gradient,
  });

  /// The widget to display on top of the background.
  final Widget child;

  /// Custom gradient. Defaults to the cosmic gradient.
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient ?? CosmicColors.cosmicGradient,
        ),
        child: child,
      );
}
