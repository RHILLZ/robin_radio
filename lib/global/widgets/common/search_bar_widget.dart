import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';

/// A customizable search bar widget with reactive visibility.
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
            height: isVisible.value ? 12.h : 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isVisible.value ? 1.0 : 0.0,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: hintText,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: onClear,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: onChanged,
                ),
              ),
            ),
          ),
        ),
      );
}
