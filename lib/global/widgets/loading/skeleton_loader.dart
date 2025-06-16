import 'package:flutter/material.dart';

/// Predefined skeleton types for common UI patterns
enum SkeletonType {
  text,
  avatar,
  image,
  button,
  card,
  listItem,
  custom,
}

/// Skeleton shape options
enum SkeletonShape {
  rectangle,
  circle,
  roundedRectangle,
}

/// A single skeleton element that can be combined to create complex loading layouts
class SkeletonElement extends StatelessWidget {
  const SkeletonElement({
    required this.width,
    required this.height,
    super.key,
    this.shape = SkeletonShape.roundedRectangle,
    this.borderRadius,
    this.color,
    this.margin,
  });

  final double width;
  final double height;
  final SkeletonShape shape;
  final BorderRadius? borderRadius;
  final Color? color;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final skeletonColor = color ??
        Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3);

    Widget skeleton;

    switch (shape) {
      case SkeletonShape.circle:
        skeleton = Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: skeletonColor,
          ),
        );
        break;

      case SkeletonShape.rectangle:
        skeleton = Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: skeletonColor,
          ),
        );
        break;

      case SkeletonShape.roundedRectangle:
        skeleton = Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: borderRadius ?? BorderRadius.circular(4),
            color: skeletonColor,
          ),
        );
        break;
    }

    if (margin != null) {
      skeleton = Padding(
        padding: margin!,
        child: skeleton,
      );
    }

    return skeleton;
  }
}

/// Main skeleton loader component with predefined patterns and custom layout support
class SkeletonLoader extends StatelessWidget {
  const SkeletonLoader({
    super.key,
    this.type = SkeletonType.custom,
    this.width,
    this.height,
    this.color,
    this.borderRadius,
    this.child,
    this.itemCount = 1,
    this.padding,
    this.spacing = 8.0,
  });

  /// Predefined skeleton type for common patterns
  final SkeletonType type;

  /// Width of the skeleton (required for some types)
  final double? width;

  /// Height of the skeleton (required for some types)
  final double? height;

  /// Color override for skeleton elements
  final Color? color;

  /// Border radius for rounded elements
  final BorderRadius? borderRadius;

  /// Custom skeleton layout (used with SkeletonType.custom)
  final Widget? child;

  /// Number of items to repeat for list-type skeletons
  final int itemCount;

  /// Padding around the entire skeleton
  final EdgeInsetsGeometry? padding;

  /// Spacing between skeleton elements
  final double spacing;

  Color _getSkeletonColor(BuildContext context) =>
      color ??
      Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3);

  Widget _buildTextSkeleton(BuildContext context) => SkeletonElement(
        width: width ?? 120,
        height: height ?? 16,
        color: _getSkeletonColor(context),
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      );

  Widget _buildAvatarSkeleton(BuildContext context) {
    final size = width ?? height ?? 40;
    return SkeletonElement(
      width: size,
      height: size,
      shape: SkeletonShape.circle,
      color: _getSkeletonColor(context),
    );
  }

  Widget _buildImageSkeleton(BuildContext context) => SkeletonElement(
        width: width ?? 100,
        height: height ?? 100,
        color: _getSkeletonColor(context),
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      );

  Widget _buildButtonSkeleton(BuildContext context) => SkeletonElement(
        width: width ?? 100,
        height: height ?? 36,
        color: _getSkeletonColor(context),
        borderRadius: borderRadius ?? BorderRadius.circular(18),
      );

  Widget _buildCardSkeleton(BuildContext context) {
    final cardWidth = width ?? double.infinity;
    final cardColor = _getSkeletonColor(context);

    return Container(
      width: cardWidth,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              SkeletonElement(
                width: 40,
                height: 40,
                shape: SkeletonShape.circle,
                color: cardColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonElement(
                      width: double.infinity,
                      height: 16,
                      color: cardColor,
                    ),
                    const SizedBox(height: 6),
                    SkeletonElement(
                      width: 100,
                      height: 12,
                      color: cardColor,
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: spacing),

          // Content image
          if (height != null && height! > 100)
            Column(
              children: [
                SkeletonElement(
                  width: double.infinity,
                  height: height! - 120,
                  color: cardColor,
                ),
                SizedBox(height: spacing),
              ],
            ),

          // Text content
          SkeletonElement(
            width: double.infinity,
            height: 14,
            color: cardColor,
          ),
          const SizedBox(height: 6),
          SkeletonElement(
            width: cardWidth * 0.8,
            height: 14,
            color: cardColor,
          ),
          const SizedBox(height: 6),
          SkeletonElement(
            width: cardWidth * 0.6,
            height: 14,
            color: cardColor,
          ),
        ],
      ),
    );
  }

  Widget _buildListItemSkeleton(BuildContext context) {
    final itemColor = _getSkeletonColor(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Leading element (avatar/image)
          SkeletonElement(
            width: 48,
            height: 48,
            shape: SkeletonShape.circle,
            color: itemColor,
          ),

          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonElement(
                  width: double.infinity,
                  height: 16,
                  color: itemColor,
                ),
                const SizedBox(height: 6),
                SkeletonElement(
                  width: 150,
                  height: 14,
                  color: itemColor,
                ),
              ],
            ),
          ),

          // Trailing element
          SkeletonElement(
            width: 24,
            height: 24,
            color: itemColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    switch (type) {
      case SkeletonType.text:
        return _buildTextSkeleton(context);
      case SkeletonType.avatar:
        return _buildAvatarSkeleton(context);
      case SkeletonType.image:
        return _buildImageSkeleton(context);
      case SkeletonType.button:
        return _buildButtonSkeleton(context);
      case SkeletonType.card:
        return _buildCardSkeleton(context);
      case SkeletonType.listItem:
        return _buildListItemSkeleton(context);
      case SkeletonType.custom:
        return child ?? const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget skeleton;

    if (type == SkeletonType.listItem && itemCount > 1) {
      skeleton = Column(
        children: List.generate(itemCount, (index) => _buildSkeleton(context)),
      );
    } else if (itemCount > 1) {
      skeleton = Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: List.generate(itemCount, (index) => _buildSkeleton(context)),
      );
    } else {
      skeleton = _buildSkeleton(context);
    }

    if (padding != null) {
      skeleton = Padding(
        padding: padding!,
        child: skeleton,
      );
    }

    return skeleton;
  }
}

/// Convenience constructors for common skeleton patterns
extension SkeletonLoaderConvenience on SkeletonLoader {
  /// Text line skeleton
  static Widget text({
    double? width,
    double? height = 16,
    Color? color,
    int lines = 1,
  }) =>
      SkeletonLoader(
        type: SkeletonType.text,
        width: width,
        height: height,
        color: color,
        itemCount: lines,
        spacing: 6,
      );

  /// Avatar/profile picture skeleton
  static Widget avatar({
    double size = 40,
    Color? color,
  }) =>
      SkeletonLoader(
        type: SkeletonType.avatar,
        width: size,
        height: size,
        color: color,
      );

  /// Image/thumbnail skeleton
  static Widget image({
    double? width,
    double? height,
    Color? color,
    BorderRadius? borderRadius,
  }) =>
      SkeletonLoader(
        type: SkeletonType.image,
        width: width,
        height: height,
        color: color,
        borderRadius: borderRadius,
      );

  /// Button skeleton
  static Widget button({
    double? width,
    double? height = 36,
    Color? color,
  }) =>
      SkeletonLoader(
        type: SkeletonType.button,
        width: width,
        height: height,
        color: color,
      );

  /// Card layout skeleton
  static Widget card({
    double? width,
    double? height,
    Color? color,
    EdgeInsetsGeometry? padding,
  }) =>
      SkeletonLoader(
        type: SkeletonType.card,
        width: width,
        height: height,
        color: color,
        padding: padding,
      );

  /// List item skeleton
  static Widget listItem({
    Color? color,
    int itemCount = 1,
  }) =>
      SkeletonLoader(
        type: SkeletonType.listItem,
        color: color,
        itemCount: itemCount,
      );

  /// Custom skeleton layout
  static Widget custom({
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) =>
      SkeletonLoader(
        padding: padding,
        child: child,
      );
}

/// Specialized skeletons for Robin Radio app content
class RadioSkeletons {
  /// Skeleton for track/song list items
  static Widget trackItem({
    Color? color,
    bool showAlbumArt = true,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            if (showAlbumArt) ...[
              SkeletonElement(
                width: 56,
                height: 56,
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonElement(
                    width: double.infinity,
                    height: 16,
                    color: color,
                  ),
                  const SizedBox(height: 6),
                  SkeletonElement(
                    width: 120,
                    height: 14,
                    color: color,
                  ),
                  const SizedBox(height: 4),
                  SkeletonElement(
                    width: 80,
                    height: 12,
                    color: color,
                  ),
                ],
              ),
            ),
            SkeletonElement(
              width: 24,
              height: 24,
              shape: SkeletonShape.circle,
              color: color,
            ),
          ],
        ),
      );

  /// Skeleton for album grid items
  static Widget albumCard({
    Color? color,
    double? size,
  }) {
    final cardSize = size ?? 150;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonElement(
          width: cardSize,
          height: cardSize,
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        const SizedBox(height: 8),
        SkeletonElement(
          width: cardSize,
          height: 16,
          color: color,
        ),
        const SizedBox(height: 4),
        SkeletonElement(
          width: cardSize * 0.7,
          height: 14,
          color: color,
        ),
      ],
    );
  }

  /// Skeleton for player view
  static Widget playerView({
    Color? color,
  }) =>
      Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Album art
            SkeletonElement(
              width: 280,
              height: 280,
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            const SizedBox(height: 32),

            // Track title
            SkeletonElement(
              width: 240,
              height: 24,
              color: color,
            ),
            const SizedBox(height: 8),

            // Artist name
            SkeletonElement(
              width: 180,
              height: 18,
              color: color,
            ),
            const SizedBox(height: 32),

            // Progress bar
            SkeletonElement(
              width: double.infinity,
              height: 4,
              color: color,
            ),
            const SizedBox(height: 24),

            // Control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SkeletonElement(
                  width: 48,
                  height: 48,
                  shape: SkeletonShape.circle,
                  color: color,
                ),
                SkeletonElement(
                  width: 64,
                  height: 64,
                  shape: SkeletonShape.circle,
                  color: color,
                ),
                SkeletonElement(
                  width: 48,
                  height: 48,
                  shape: SkeletonShape.circle,
                  color: color,
                ),
              ],
            ),
          ],
        ),
      );
}
