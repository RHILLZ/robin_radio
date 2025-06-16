import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({
    required this.isVisible,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
    super.key,
    this.hintText = 'Search...',
  });

  final RxBool isVisible;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
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
