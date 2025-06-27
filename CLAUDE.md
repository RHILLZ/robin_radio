# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Robin Radio is a Flutter music streaming application built with clean architecture principles. The project uses GetX for state management, Firebase for backend services, and follows enterprise-grade development patterns with comprehensive testing and performance monitoring.

## Key Development Commands

### Build & Development
```bash
flutter run                    # Run the app in development mode
flutter build apk             # Build Android APK
flutter build ios             # Build iOS app
flutter build web             # Build web version
```

### Code Quality & Testing
```bash
flutter test                   # Run unit and widget tests
flutter analyze              # Static code analysis
dart format .                 # Format Dart code
flutter pub get              # Install dependencies
flutter pub upgrade          # Update dependencies
```

### Asset Management
```bash
./scripts/convert_to_webp.sh  # Convert PNG assets to WebP format
flutter pub run flutter_launcher_icons:main  # Generate app icons
flutter pub run flutter_native_splash:create # Generate splash screens
```

### Firebase Setup
```bash
flutterfire configure         # Configure Firebase for the project
```

## Architecture Overview

### Clean Architecture Structure
```
lib/
├── core/              # Dependency injection & environment setup
├── data/              # Data layer (repositories, services, models)
├── global/            # Shared UI components and widgets  
├── modules/           # Feature modules (app, home, player)
├── routes/            # Navigation configuration
└── main.dart          # Application entry point
```

### Key Architectural Patterns

**Service Locator Pattern**: Centralized dependency injection using GetX
- Located in `lib/core/di/service_locator.dart`
- Environment-specific configurations (Development, Testing, Production)
- Hierarchical service registration with comprehensive error handling

**Repository Pattern**: Abstract data access with multiple implementations
- Interface: `IMusicRepository` 
- Production: `FirebaseMusicRepository` (Firebase Storage integration)
- Testing: `MockMusicRepository` (sample data for development)

**Enhanced Service Architecture**:
- `INetworkService`: HTTP client and connectivity management
- `ICacheService`: Memory and disk caching with Flutter Cache Manager
- `IAudioService`: Media playback with audioplayers and just_audio support
- `PerformanceService`: Firebase Performance monitoring integration

### State Management
- **GetX**: Primary state management solution
- Controllers follow GetX patterns with dependency injection
- Reactive state updates using GetX observables

## Testing Strategy

### Test Structure
```
test/
├── service_locator_test.dart  # Dependency injection tests
├── audio_service_test.dart    # Audio playback tests
├── cache_service_test.dart    # Caching functionality tests
├── network_service_test.dart  # Network connectivity tests
└── widget_test.dart          # Basic widget tests
```

### Testing Approach
- Environment-specific service configurations for testing
- Comprehensive mock implementations for all major services
- Repository cache-only testing for offline scenarios
- Performance testing and benchmarking capabilities

## Firebase Integration

### Services Used
- **Firebase Core**: Base Firebase functionality
- **Firebase Storage**: Music file storage and retrieval
- **Firebase Performance**: App performance monitoring and traces

### Performance Monitoring
Key traces monitored:
- App startup performance
- Music loading and buffering times
- Album loading and caching performance

## Development Guidelines

### Code Style
- Follow Dart/Flutter conventions as defined in `analysis_options.yaml`
- 100+ lint rules enabled for strict code quality
- Null safety enforced throughout the codebase
- Use meaningful variable names and maintain consistent formatting

### Service Implementation
- All services implement interfaces for testability
- Use dependency injection through ServiceLocator
- Handle errors gracefully with proper exception classes in `lib/data/exceptions/`
- Implement caching strategies for performance optimization

### Asset Optimization
- Use WebP format for images (conversion script available)
- Implement proper image caching with CachedNetworkImage
- Follow Flutter's asset naming conventions

### Audio Implementation
- Background playback configured for iOS (`UIBackgroundModes: audio`)
- Bluetooth and AirPlay support integrated
- Multiple audio libraries supported (current: audioplayers, future: just_audio)

## Key Files & Locations

### Configuration
- `pubspec.yaml`: Dependencies and project configuration
- `analysis_options.yaml`: Linting rules and code quality settings
- `firebase_options.dart`: Firebase platform-specific configuration
- `assets/appainter_theme.json`: Custom theme configuration

### Core Services
- `lib/core/di/service_locator.dart`: Dependency injection setup
- `lib/data/services/`: All service implementations
- `lib/data/repositories/`: Data access layer implementations
- `lib/data/models/`: Data models with JSON serialization

### UI Components
- `lib/global/widgets/`: Reusable UI components
- `lib/modules/`: Feature-specific views and controllers
- `lib/routes/`: Navigation and routing configuration

### Testing
- All major services have corresponding test files in `test/`
- Mock implementations available for offline development
- Integration tests for repository caching behavior

## Task Management Integration

This project uses Task Master for development workflow management via MCP server integration. Key commands and patterns are defined in `.cursor/rules/dev_workflow.mdc` and related rule files.

## Common Workflows

### Adding New Features
1. Implement service interfaces if needed
2. Add repository methods for data access
3. Create controllers with GetX patterns
4. Build UI components following existing patterns
5. Add comprehensive tests for new functionality
6. Update Firebase configuration if backend changes needed

### Performance Optimization
1. Use Firebase Performance monitoring to identify bottlenecks
2. Implement proper caching strategies with ICacheService
3. Optimize image loading with CachedNetworkImage
4. Profile audio playback performance
5. Monitor memory usage during development

### Testing New Changes
1. Run unit tests: `flutter test`
2. Test on multiple platforms (Android, iOS, Web)
3. Verify Firebase integration in staging environment
4. Check performance metrics in Firebase console
5. Validate offline functionality with mock services
```

## Claude Code Memory

- When testing with "flutter build" always prioritize flutter build ios unless specifically asked for web or apk