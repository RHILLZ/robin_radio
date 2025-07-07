import 'package:flutter/material.dart';
import 'breakpoints.dart';
import 'responsive_builder.dart';

/// A responsive grid layout that automatically adjusts columns based on screen size.
///
/// Provides intelligent column counting and spacing that adapts to different
/// device types and screen sizes for optimal content presentation.
class ResponsiveGrid extends StatelessWidget {
  /// Creates a responsive grid layout.
  ///
  /// The [children] are laid out in a grid with columns that automatically
  /// adjust based on screen size. Column counts can be customized per device type.
  const ResponsiveGrid({
    required this.children,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.spacing = 16.0,
    this.runSpacing,
    this.crossAxisAlignment = WrapCrossAlignment.start,
    this.mainAxisAlignment = WrapAlignment.start,
    this.padding,
    super.key,
  });

  /// The widgets to display in the grid.
  final List<Widget> children;

  /// Number of columns on mobile devices (default: auto-calculated).
  final int? mobileColumns;

  /// Number of columns on tablet devices (default: auto-calculated).
  final int? tabletColumns;

  /// Number of columns on desktop devices (default: auto-calculated).
  final int? desktopColumns;

  /// Spacing between grid items horizontally.
  final double spacing;

  /// Spacing between grid rows vertically (defaults to [spacing] value).
  final double? runSpacing;

  /// How the children within a run should be placed in the cross axis.
  final WrapCrossAlignment crossAxisAlignment;

  /// How the runs themselves should be placed in the main axis.
  final WrapAlignment mainAxisAlignment;

  /// Padding around the entire grid.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => ResponsiveBuilder(
        builder: (context, constraints, deviceType, screenSize) {
          final columns = _getColumns(deviceType);
          final itemWidth = _calculateItemWidth(constraints.maxWidth, columns);

          final paddedChildren = children
              .map((child) => SizedBox(width: itemWidth, child: child))
              .toList();

          final grid = Wrap(
            spacing: spacing,
            runSpacing: runSpacing ?? spacing,
            crossAxisAlignment: crossAxisAlignment,
            alignment: mainAxisAlignment,
            children: paddedChildren,
          );

          return padding != null
              ? Padding(padding: padding!, child: grid)
              : grid;
        },
      );

  /// Determines the number of columns based on device type and custom settings.
  int _getColumns(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return mobileColumns ?? 2;
      case DeviceType.tablet:
        return tabletColumns ?? 3;
      case DeviceType.desktop:
        return desktopColumns ?? 4;
    }
  }

  /// Calculates the width for each grid item based on available space and columns.
  double _calculateItemWidth(double totalWidth, int columns) {
    final totalSpacing = spacing * (columns - 1);
    final paddingWidth = padding?.horizontal ?? 0;
    final availableWidth = totalWidth - totalSpacing - paddingWidth;
    return availableWidth / columns;
  }
}

/// A responsive staggered grid for items with varying heights.
///
/// Similar to ResponsiveGrid but allows items to have different heights
/// and automatically arranges them in a staggered layout.
class ResponsiveStaggeredGrid extends StatelessWidget {
  /// Creates a responsive staggered grid layout.
  const ResponsiveStaggeredGrid({
    required this.children,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.spacing = 16.0,
    this.runSpacing,
    this.padding,
    super.key,
  });

  /// The widgets to display in the staggered grid.
  final List<Widget> children;

  /// Number of columns on mobile devices (default: 2).
  final int? mobileColumns;

  /// Number of columns on tablet devices (default: 3).
  final int? tabletColumns;

  /// Number of columns on desktop devices (default: 4).
  final int? desktopColumns;

  /// Spacing between grid items.
  final double spacing;

  /// Spacing between grid rows (defaults to [spacing] value).
  final double? runSpacing;

  /// Padding around the entire grid.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => ResponsiveBuilder(
        builder: (context, constraints, deviceType, screenSize) {
          final columns = _getColumns(deviceType);
          final itemWidth = _calculateItemWidth(constraints.maxWidth, columns);

          // Create column lists to distribute items
          final columnLists = List.generate(columns, (_) => <Widget>[]);

          // Distribute children across columns
          for (var i = 0; i < children.length; i++) {
            final columnIndex = i % columns;
            columnLists[columnIndex].add(
              SizedBox(
                width: itemWidth,
                child: children[i],
              ),
            );
          }

          // Create columns with spacing
          final gridColumns = columnLists
              .map(
                (columnChildren) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: columnChildren
                      .expand(
                        (child) => [
                          child,
                          if (child != columnChildren.last)
                            SizedBox(height: runSpacing ?? spacing),
                        ],
                      )
                      .toList(),
                ),
              )
              .toList();

          final grid = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: gridColumns
                .expand(
                  (column) => [
                    Expanded(child: column),
                    if (column != gridColumns.last) SizedBox(width: spacing),
                  ],
                )
                .toList(),
          );

          return padding != null
              ? Padding(padding: padding!, child: grid)
              : grid;
        },
      );

  /// Determines the number of columns based on device type and custom settings.
  int _getColumns(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return mobileColumns ?? 2;
      case DeviceType.tablet:
        return tabletColumns ?? 3;
      case DeviceType.desktop:
        return desktopColumns ?? 4;
    }
  }

  /// Calculates the width for each grid item based on available space and columns.
  double _calculateItemWidth(double totalWidth, int columns) {
    final totalSpacing = spacing * (columns - 1);
    final paddingWidth = padding?.horizontal ?? 0;
    final availableWidth = totalWidth - totalSpacing - paddingWidth;
    return availableWidth / columns;
  }
}

/// A responsive list that switches between list and grid layouts.
///
/// Automatically chooses between a vertical list layout for small screens
/// and a grid layout for larger screens.
class ResponsiveListGrid extends StatelessWidget {
  /// Creates a responsive list that adapts between list and grid layouts.
  const ResponsiveListGrid({
    required this.children,
    this.forceGrid = false,
    this.forceList = false,
    this.gridColumns,
    this.spacing = 16.0,
    this.padding,
    super.key,
  });

  /// The widgets to display.
  final List<Widget> children;

  /// Force grid layout regardless of screen size.
  final bool forceGrid;

  /// Force list layout regardless of screen size.
  final bool forceList;

  /// Number of columns when in grid mode (auto-calculated if null).
  final int? gridColumns;

  /// Spacing between items.
  final double spacing;

  /// Padding around the layout.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => ResponsiveBuilder(
        builder: (context, constraints, deviceType, screenSize) {
          final useGrid =
              forceGrid || (!forceList && deviceType != DeviceType.mobile);

          if (useGrid) {
            return ResponsiveGrid(
              spacing: spacing,
              padding: padding,
              desktopColumns: gridColumns,
              tabletColumns: gridColumns,
              mobileColumns: gridColumns,
              children: children,
            );
          } else {
            final list = Column(
              children: children
                  .expand(
                    (child) => [
                      child,
                      if (child != children.last) SizedBox(height: spacing),
                    ],
                  )
                  .toList(),
            );

            return padding != null
                ? Padding(padding: padding!, child: list)
                : list;
          }
        },
      );
}
