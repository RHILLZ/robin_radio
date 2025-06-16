import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:sizer/sizer.dart';

class LoadingStateWidget extends StatelessWidget {
  const LoadingStateWidget({
    required this.title,
    required this.message,
    required this.progress,
    super.key,
    this.showProgress = true,
  });

  final String title;
  final String message;
  final double progress;
  final bool showProgress;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SpinKitChasingDots(
                color: Colors.deepPurpleAccent,
              ),
              SizedBox(height: 2.h),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 1.h),
              Text(
                message,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              if (showProgress) ...[
                SizedBox(height: 3.h),
                SizedBox(
                  width: 80.w,
                  child: Column(
                    children: [
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        '${(progress * 100).toInt()}% Complete',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}
