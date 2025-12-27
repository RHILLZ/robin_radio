import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';

import '../../cosmic_theme.dart';

/// A customizable search bar widget with reactive visibility and cosmic styling.
class SearchBarWidget extends StatelessWidget {
  /// Creates a SearchBarWidget with the given parameters.
  const SearchBarWidget({
    required this.isVisible,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
    super.key,
    this.hintText = 'Search...',
  });

  /// Reactive boolean to control visibility of the search bar.
  final RxBool isVisible;

  /// Text controller for the search input field.
  final TextEditingController controller;

  /// Focus node for managing keyboard focus.
  final FocusNode focusNode;

  /// Callback triggered when the text changes.
  final ValueChanged<String> onChanged;

  /// Callback triggered when the clear button is pressed.
  final VoidCallback onClear;

  /// Hint text displayed in the search field.
  final String hintText;

  @override
  Widget build(BuildContext context) => Obx(
        () => RepaintBoundary(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: isVisible.value ? 10.h : 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isVisible.value ? 1.0 : 0.0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: CosmicColors.cardGradient(opacity: 0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              CosmicColors.lavenderGlow.withValues(alpha: 0.2),
                        ),
                        boxShadow: CosmicColors.ambientGlow(intensity: 0.2),
                      ),
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        cursorColor: CosmicColors.lavenderGlow,
                        decoration: InputDecoration(
                          hintText: hintText,
                          hintStyle: TextStyle(
                            color:
                                CosmicColors.lavenderGlow.withValues(alpha: 0.5),
                            fontSize: 16,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color:
                                CosmicColors.lavenderGlow.withValues(alpha: 0.7),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: CosmicColors.lavenderGlow
                                  .withValues(alpha: 0.7),
                            ),
                            onPressed: onClear,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 16,
                          ),
                        ),
                        onChanged: onChanged,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
