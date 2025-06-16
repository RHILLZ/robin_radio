import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ErrorStateWidget extends StatelessWidget {
  const ErrorStateWidget({
    required this.title,
    required this.message,
    required this.onRetry,
    super.key,
    this.icon = Icons.error_outline,
    this.iconColor = Colors.red,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 80,
                color: iconColor,
              ),
              SizedBox(height: 2.h),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 1.h),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              SizedBox(height: 3.h),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
}
