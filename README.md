# HolyNikkah - Flutter Application

A Flutter application for matrimonial services with VIP and normal registration options.

## Project Structure

```
lib/
├── core/                           # Core application components
│   ├── provider/                   # Global state management
│   ├── router/                     # Auto Route navigation
│   │   ├── app_router.dart        # Route definitions
│   │   └── app_router.gr.dart     # Generated routes (auto-generated)
│   ├── services/                   # External services
│   ├── theme/                      # App theming
│   ├── utils/                      # Utility functions
│   └── widgets/                    # Reusable widgets
│       ├── common_dropdown.dart    # Dropdown component
│       ├── common_text_field.dart  # Text input component
│       └── widgets.dart           # Widget exports
├── models/                         # Data models
├── modules/                        # Feature modules
│   ├── ads/                       # Advertisement module
│   ├── category/                  # Category selection
│   ├── donaters/                  # Donation module
│   ├── home/                      # Home screen
│   ├── login/                     # Authentication
│   ├── reels/                     # Video reels
│   ├── registration/              # User registration
│   │   ├── providers/             # Registration state
│   │   └── screens/               # Registration screens
│   ├── settings/                  # App settings
│   └── splash/                    # Splash screen
├── application.dart               # App configuration
├── main.dart                      # App entry point
└── multi_provider.dart           # Provider setup
```

## Key Dependencies

- **flutter_screenutil**: Responsive UI scaling
- **auto_route**: Type-safe navigation
- **provider**: State management
- **google_fonts**: Custom fonts
- **dropdown_button2**: Enhanced dropdowns
- **image_picker**: Image selection
- **flutter_secure_storage**: Secure data storage

## Development Guidelines

### When Adding New Features

1. **Create Feature Module**:
   ```
   lib/modules/feature_name/
   ├── providers/          # Feature-specific state
   ├── screens/           # UI screens
   ├── widgets/           # Feature widgets
   └── models/            # Feature models
   ```

2. **Add Routes**:
   - Add route in `lib/core/router/app_router.dart`
   - Run `flutter packages pub run build_runner build --delete-conflicting-outputs`

3. **State Management**:
   - Create providers in feature's `providers/` folder
   - Add to `multi_provider.dart` if global

### When Modifying UI Components

1. **Common Widgets**:
   - Update in `lib/core/widgets/`
   - Export in `widgets.dart`
   - Follow existing naming: `Common[ComponentName]`

2. **Styling**:
   - Use `flutter_screenutil` for responsive sizing
   - Follow theme colors from `AppColors`
   - Use `GoogleFonts.inter()` for typography

### When Adding Dependencies

1. **Add to pubspec.yaml**:
   ```yaml
   dependencies:
     new_package: ^version
   ```

2. **Run commands**:
   ```bash
   flutter pub get
   # If code generation needed:
   flutter packages pub run build_runner build --delete-conflicting-outputs
   ```

### When Working with Forms

1. **Validation**:
   - Use form validation for UI feedback
   - Show SnackBar for comprehensive errors
   - Validate all required fields before submission

2. **Dropdowns**:
   - Use `CommonDropdown` with `ValueNotifier`
   - Implement cascading selections when needed
   - Dispose ValueNotifiers in widget disposal

### Code Generation Commands

```bash
# Generate routes after adding new routes
flutter packages pub run build_runner build --delete-conflicting-outputs

# Watch for changes during development
flutter packages pub run build_runner watch --delete-conflicting-outputs

# Clean generated files
flutter packages pub run build_runner clean
```

### Common Issues & Solutions

1. **Route Generation Errors**:
   - Ensure `@RoutePage()` annotation on page widgets
   - Run build_runner after route changes
   - Check for missing required parameters

2. **State Management**:
   - Use `ValueNotifier` for simple reactive state
   - Use `Provider` for complex state management
   - Always dispose controllers and notifiers

3. **UI Responsiveness**:
   - Use `.w`, `.h`, `.sp`, `.r` extensions from screenutil
   - Test on different screen sizes
   - Follow material design guidelines

### File Naming Conventions

- **Screens**: `feature_name_screen.dart`
- **Widgets**: `common_widget_name.dart`
- **Providers**: `feature_name_provider.dart`
- **Models**: `model_name.dart`
- **Routes**: Use PascalCase with `Route` suffix

### Testing

```bash
# Run tests
flutter test

# Run with coverage
flutter test --coverage

# Analyze code
flutter analyze
```

## Getting Started

1. **Clone and Setup**:
   ```bash
   git clone <repository>
   cd holynikkah
   flutter pub get
   flutter packages pub run build_runner build --delete-conflicting-outputs
   ```

2. **Run Application**:
   ```bash
   flutter run
   ```

3. **Build for Release**:
   ```bash
   flutter build apk --release
   flutter build ios --release
   ```

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
