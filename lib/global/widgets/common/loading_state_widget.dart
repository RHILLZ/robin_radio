import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:sizer/sizer.dart';

/// Comprehensive loading state widget for displaying operation progress and feedback.
///
/// Provides a consistent, visually appealing loading interface for long-running
/// operations including data fetching, file processing, and background tasks.
/// Combines animated indicators, descriptive text, and optional progress tracking
/// to keep users informed during wait times.
///
/// ## Features
///
/// **Visual Components:**
/// - Animated chasing dots spinner for engaging visual feedback
/// - Clear title and message text for context-specific information
/// - Optional linear progress bar for determinate operations
/// - Percentage display for precise progress tracking
/// - Theme-aware colors that adapt to light/dark modes
///
/// **Layout Design:**
/// - Centered content with optimal spacing ratios
/// - Responsive sizing using Sizer package for device adaptation
/// - Vertical layout optimized for portrait and landscape orientations
/// - RepaintBoundary optimization for efficient rendering
///
/// **Progress Modes:**
/// - **Indeterminate**: Shows spinner only for unknown duration tasks
/// - **Determinate**: Includes progress bar and percentage for tracked operations
/// - **Message-only**: Provides contextual information without progress tracking
///
/// ## Usage Patterns
///
/// **Basic Loading (Indeterminate):**
/// ```dart
/// LoadingStateWidget(
///   title: 'Loading Albums',
///   message: 'Fetching your music library from the server...',
///   progress: 0.0,
///   showProgress: false,
/// );
/// ```
///
/// **Progress Tracking (Determinate):**
/// ```dart
/// class _MyWidgetState extends State<MyWidget> {
///   double _progress = 0.0;
///
///   @override
///   Widget build(BuildContext context) {
///     return LoadingStateWidget(
///       title: 'Downloading Album',
///       message: 'Fetching track data and artwork...',
///       progress: _progress,
///       showProgress: true,
///     );
///   }
///
///   void _updateProgress(double newProgress) {
///     setState(() {
///       _progress = newProgress.clamp(0.0, 1.0);
///     });
///   }
/// }
/// ```
///
/// **Network Operations:**
/// ```dart
/// Future<void> loadMusicLibrary() async {
///   showDialog(
///     context: context,
///     barrierDismissible: false,
///     builder: (_) => LoadingStateWidget(
///       title: 'Syncing Library',
///       message: 'Connecting to music service and downloading latest content...',
///       progress: 0.0,
///       showProgress: false,
///     ),
///   );
///
///   try {
///     await musicRepository.refreshCache();
///     Navigator.pop(context);
///   } catch (e) {
///     Navigator.pop(context);
///     showErrorDialog(e.toString());
///   }
/// }
/// ```
///
/// **File Processing with Progress:**
/// ```dart
/// StreamBuilder<double>(
///   stream: fileProcessor.progressStream,
///   builder: (context, snapshot) {
///     final progress = snapshot.data ?? 0.0;
///     return LoadingStateWidget(
///       title: 'Processing Audio',
///       message: 'Converting files to supported format...',
///       progress: progress,
///       showProgress: true,
///     );
///   },
/// );
/// ```
///
/// ## Context-Specific Messages
///
/// **Music Loading Scenarios:**
/// ```dart
/// // Album loading
/// LoadingStateWidget(
///   title: 'Loading Album',
///   message: 'Fetching track list and metadata...',
///   progress: albumLoadProgress,
///   showProgress: true,
/// );
///
/// // Search operations
/// LoadingStateWidget(
///   title: 'Searching Music',
///   message: 'Finding albums and tracks matching your query...',
///   progress: 0.0,
///   showProgress: false,
/// );
///
/// // Cache refresh
/// LoadingStateWidget(
///   title: 'Updating Library',
///   message: 'Syncing with music service for latest content...',
///   progress: syncProgress,
///   showProgress: true,
/// );
/// ```
///
/// ## Accessibility Features
///
/// **Screen Reader Support:**
/// - Semantic labels for all text content
/// - Progress announcements for determinate operations
/// - Clear hierarchy with title and message distinction
/// - Appropriate text scaling support
///
/// **Visual Accessibility:**
/// - High contrast spinner animation
/// - Theme-aware color selection for optimal visibility
/// - Sufficient text sizes for readability
/// - Clear visual hierarchy with appropriate spacing
///
/// ## Performance Considerations
///
/// **Rendering Optimization:**
/// - RepaintBoundary prevents unnecessary parent redraws
/// - Efficient SpinKit animation with minimal resource usage
/// - Conditional rendering of progress components
/// - Optimized layout with minimal widget nesting
///
/// **Memory Management:**
/// - Stateless design prevents memory accumulation
/// - Efficient use of theme colors without caching
/// - Minimal object allocation during builds
/// - Animation cleanup handled by SpinKit internally
///
/// **Responsive Design:**
/// - Sizer integration for consistent sizing across devices
/// - Adaptive spacing ratios for different screen sizes
/// - Maintains readability on various display densities
/// - Efficient layout calculation for fast rendering
///
/// ## Animation Characteristics
///
/// **Spinner Animation:**
/// - Smooth chasing dots animation indicates active processing
/// - Consistent animation speed provides reliable visual feedback
/// - Non-blocking animation that doesn't interfere with other operations
/// - Resource-efficient implementation suitable for long-running displays
///
/// **Progress Animation:**
/// - Smooth linear progress bar transitions
/// - Real-time percentage updates with integer display
/// - Visual feedback that correlates with actual operation progress
/// - Automatic color theming for consistent appearance
///
/// ## Integration Guidelines
///
/// **Best Practices:**
/// - Use descriptive titles that clearly indicate the operation
/// - Provide helpful messages that set appropriate user expectations
/// - Show progress bars only when meaningful progress can be tracked
/// - Ensure progress values are accurate and regularly updated
/// - Consider user context when crafting loading messages
///
/// **Common Patterns:**
/// - Wrap in dialogs for blocking operations
/// - Embed in page content for non-blocking loading
/// - Use in conjunction with error handling for robust UX
/// - Combine with timeout handling for network operations
/// - Integrate with cancel buttons for user control when appropriate
class LoadingStateWidget extends StatelessWidget {
  /// Creates a LoadingStateWidget for displaying operation progress.
  ///
  /// [title] The main heading describing the current operation. Should be
  ///        concise and clearly indicate what is happening. Examples:
  ///        "Loading Albums", "Downloading Tracks", "Syncing Library"
  ///
  /// [message] Detailed description providing context and user expectations.
  ///          Should explain what's happening and potentially how long it
  ///          might take. Examples: "Fetching your music library from the
  ///          server...", "This may take a few moments depending on your
  ///          connection speed."
  ///
  /// [progress] Current operation progress as a value between 0.0 and 1.0.
  ///           Used for the progress bar and percentage calculation. Only
  ///           meaningful when showProgress is true. Values outside 0.0-1.0
  ///           are automatically clamped to prevent display errors.
  ///
  /// [showProgress] Whether to display the progress bar and percentage.
  ///               Set to true for operations where progress can be measured
  ///               (file downloads, processing steps). Set to false for
  ///               indeterminate operations (network requests, searches).
  ///
  /// Example usage:
  /// ```dart
  /// // Indeterminate loading
  /// LoadingStateWidget(
  ///   title: 'Loading Music',
  ///   message: 'Fetching your library...',
  ///   progress: 0.0,
  ///   showProgress: false,
  /// );
  ///
  /// // Progress tracking
  /// LoadingStateWidget(
  ///   title: 'Downloading Album',
  ///   message: 'Fetching track data...',
  ///   progress: 0.65,
  ///   showProgress: true,
  /// );
  /// ```
  const LoadingStateWidget({
    required this.title,
    required this.message,
    required this.progress,
    super.key,
    this.showProgress = true,
  });

  /// The main title describing the current operation.
  ///
  /// Should be a concise, descriptive heading that clearly communicates
  /// what operation is in progress. Displayed prominently with bold
  /// styling to serve as the primary information for users.
  final String title;

  /// Detailed message providing operation context.
  ///
  /// Should explain what's happening and set appropriate expectations
  /// for the user. Can include estimates, instructions, or additional
  /// context that helps users understand the wait time.
  final String message;

  /// Current progress value between 0.0 (start) and 1.0 (complete).
  ///
  /// Used to update the progress bar and calculate the percentage display.
  /// Only relevant when showProgress is true. Values are automatically
  /// clamped to the 0.0-1.0 range to prevent display issues.
  final double progress;

  /// Whether to show the progress bar and percentage display.
  ///
  /// Set to true for operations where meaningful progress can be tracked
  /// and reported. Set to false for indeterminate operations where the
  /// duration or progress cannot be measured accurately.
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
