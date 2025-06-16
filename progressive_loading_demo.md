# Progressive Image Loading Implementation

This document demonstrates the progressive loading features implemented in the Robin Radio Flutter app's `ImageLoader` widget.

## Overview

Progressive image loading provides a smooth user experience by showing intermediate content while the main image loads. This reduces perceived loading time and prevents jarring layout shifts.

## Progressive Loading Modes

### 1. Blur-Up Effect (`ProgressiveLoadingMode.blurUp`)

**Best for**: Thumbnails and small images where visual continuity is important.

**How it works**:

1. Loads a small, low-quality, blurred thumbnail first
2. Displays the thumbnail with blur effect
3. Simultaneously loads the full-resolution image
4. Animates from blurred thumbnail to crisp image with fade transition
5. Gradually reduces blur during transition

**Usage Example**:

```dart
ImageLoader(
  imageUrl: 'https://example.com/album-cover.jpg',
  width: 150,
  height: 150,
  context: ImageContext.thumbnail,
  progressiveMode: ProgressiveLoadingMode.blurUp,
  transitionDuration: const Duration(milliseconds: 500),
)
```

**Implemented in**: MiniPlayer widget (40×40px album covers)

### 2. Two-Phase Loading (`ProgressiveLoadingMode.twoPhase`)

**Best for**: Medium to large images where you want clear preview before final image.

**How it works**:

1. Loads a clear, medium-quality thumbnail (100px)
2. Shows thumbnail immediately when loaded
3. Loads full-resolution image in background
4. Fades from thumbnail to full image

**Usage Example**:

```dart
ImageLoader(
  imageUrl: 'https://example.com/album-cover.jpg',
  width: 300,
  height: 300,
  context: ImageContext.detailView,
  progressiveMode: ProgressiveLoadingMode.twoPhase,
  transitionDuration: const Duration(milliseconds: 800),
)
```

**Implemented in**: PlayerView widget (80w×80w album covers)

### 3. Fade Loading (`ProgressiveLoadingMode.fade`)

**Best for**: Large images where smooth appearance is more important than preview.

**How it works**:

1. Shows placeholder/loading indicator
2. Loads full-resolution image
3. Fades in the image when loading completes

**Usage Example**:

```dart
ImageLoader(
  imageUrl: 'https://example.com/album-cover.jpg',
  width: 400,
  height: 400,
  context: ImageContext.detailView,
  progressiveMode: ProgressiveLoadingMode.fade,
  transitionDuration: const Duration(milliseconds: 600),
)
```

**Implemented in**: AlbumCover widget

### 4. Standard Loading (`ProgressiveLoadingMode.none`)

**Best for**: When progressive loading is not needed or causes issues.

**How it works**:

- Traditional loading with placeholder → image transition
- No intermediate states

## Technical Implementation

### Animation Controllers

```dart
class _ImageLoaderState extends State<ImageLoader> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _blurController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _blurAnimation;
}
```

### Blur Effect Implementation

```dart
ImageFiltered(
  imageFilter: ui.ImageFilter.blur(
    sigmaX: _blurAnimation.value,
    sigmaY: _blurAnimation.value,
  ),
  child: CachedNetworkImage(/* thumbnail */),
)
```

### Thumbnail URL Generation

```dart
static String generateThumbnailUrl(String originalUrl, {int maxSize = 50}) {
  final uri = Uri.tryParse(originalUrl);
  if (uri == null) return originalUrl;

  final queryParams = Map<String, String>.from(uri.queryParameters);
  queryParams['width'] = maxSize.toString();
  queryParams['height'] = maxSize.toString();
  queryParams['quality'] = '30'; // Low quality for thumbnails
  queryParams['blur'] = '5'; // Add blur for blur-up effect

  return uri.replace(queryParameters: queryParams).toString();
}
```

## Hero Animations Integration

Progressive loading works seamlessly with Hero animations for smooth transitions between screens:

```dart
ImageLoader(
  imageUrl: imageUrl,
  heroTag: 'player_cover_${song.id}',
  progressiveMode: ProgressiveLoadingMode.twoPhase,
)
```

## Performance Benefits

### Memory Optimization

- **Blur-up**: 50px thumbnails vs full resolution
- **Two-phase**: 100px thumbnails vs full resolution
- **Smart caching**: Different cache sizes per use case

### Bandwidth Savings

- Thumbnails use 30% quality vs 85% for full images
- Smaller images for initial display
- Server-side resizing reduces download size

### User Experience

- **Faster Time to First Paint**: Thumbnails load in ~100-200ms
- **Smooth Transitions**: No jarring content jumps
- **Perceived Performance**: Users see content immediately

## Widget Integration Examples

### MiniPlayer (Thumbnail Context)

```dart
ImageLoader(
  imageUrl: controller.coverURL!,
  width: 40,
  height: 40,
  context: ImageContext.thumbnail,
  progressiveMode: ProgressiveLoadingMode.blurUp,
  transitionDuration: const Duration(milliseconds: 500),
  heroTag: 'mini_player_cover_${controller.currentSong?.songName}',
)
```

### PlayerView (Detail Context)

```dart
ImageLoader(
  imageUrl: controller.coverURL ?? '',
  width: 80.w,
  height: 80.w,
  context: ImageContext.detailView,
  progressiveMode: ProgressiveLoadingMode.twoPhase,
  transitionDuration: const Duration(milliseconds: 800),
  heroTag: 'player_cover_${controller.currentSong?.songName}',
)
```

### RadioView (Detail Context with Blur-up)

```dart
ImageLoader(
  imageUrl: controller.coverURL!,
  width: 60.w,
  height: 60.w,
  context: ImageContext.detailView,
  progressiveMode: ProgressiveLoadingMode.blurUp,
  transitionDuration: const Duration(milliseconds: 700),
  heroTag: 'radio_cover_${controller.currentRadioSong?.songName}',
)
```

## Testing Progressive Loading

### Manual Testing

1. **Slow Network**: Test on 3G or throttled connection
2. **Fast Network**: Verify transitions aren't jarring on fast connections
3. **Error Handling**: Test with invalid URLs
4. **Memory Usage**: Monitor memory consumption during scrolling

### Metrics to Track

- **Time to First Paint**: Thumbnail appearance time
- **Time to Full Resolution**: Final image load time
- **Memory Usage**: Peak memory during image operations
- **Cache Hit Ratio**: Effectiveness of caching strategy

### Test Scenarios

```dart
// Test blur-up on slow connection
ImageLoader(
  imageUrl: 'https://via.placeholder.com/800x800/ff0000/ffffff',
  progressiveMode: ProgressiveLoadingMode.blurUp,
)

// Test two-phase with medium image
ImageLoader(
  imageUrl: 'https://via.placeholder.com/400x400/00ff00/ffffff',
  progressiveMode: ProgressiveLoadingMode.twoPhase,
)

// Test fade with large image
ImageLoader(
  imageUrl: 'https://via.placeholder.com/1200x1200/0000ff/ffffff',
  progressiveMode: ProgressiveLoadingMode.fade,
)
```

## Configuration Options

### Transition Duration

Control animation speed based on context:

- **Thumbnails**: 300-500ms (quick)
- **Detail views**: 600-800ms (smooth)
- **Hero transitions**: 500-700ms (natural)

### Custom Placeholder/Error Widgets

```dart
ImageLoader(
  imageUrl: imageUrl,
  placeholder: (context, url) => CustomLoadingWidget(),
  errorWidget: (context, url, error) => CustomErrorWidget(),
)
```

### Server-Side Resizing Parameters

- **Quality**: 30% for thumbnails, 85% for full images
- **Format**: Prefer WebP when supported
- **Dimensions**: Contextual sizing based on display requirements

## Best Practices

1. **Choose appropriate mode** for each use case
2. **Set reasonable transition durations** (300-800ms)
3. **Use Hero tags** for screen transitions
4. **Test on slow networks** to verify user experience
5. **Monitor memory usage** especially in list views
6. **Provide fallbacks** for null URLs
7. **Use context-appropriate sizing** for optimal performance

## Future Enhancements

- **Adaptive quality**: Adjust based on network speed
- **Preloading**: Load next images in lists
- **WebP/AVIF support**: Modern format detection
- **Lazy loading**: Load images as they enter viewport
- **Custom animation curves**: Per-context easing functions
