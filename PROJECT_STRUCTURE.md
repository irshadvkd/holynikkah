# HolyNikah - Project Structure

## 📁 Project Architecture

```
lib/
├── core/                           # Core functionality
│   ├── provider/                   # Global providers
│   ├── router/                     # Auto Route configuration
│   ├── services/                   # Core services
│   ├── utils/                      # Utilities & constants
│   └── widgets/                    # Common reusable widgets
│       ├── common_badge.dart
│       ├── common_bottom_nav.dart
│       ├── common_button.dart
│       ├── common_otp_field.dart
│       ├── common_text_field.dart
│       ├── custom_text_field.dart
│       ├── logo_widget.dart
│       └── widgets.dart           # Export file
├── modules/                        # Feature modules
│   ├── auth/                      # Authentication module
│   │   ├── models/
│   │   ├── providers/
│   │   ├── screens/
│   │   ├── services/
│   │   └── widgets/
│   └── registration/              # Registration module
│       ├── models/
│       ├── providers/
│       ├── screens/
│       ├── services/
│       └── widgets/
├── application.dart               # Main app widget
├── main.dart                     # Entry point
└── multi_provider.dart           # Provider setup
```

## 🚀 Key Features

### ✅ Auto Route Navigation
- Type-safe navigation
- Generated routes
- Easy parameter passing

### ✅ Common Widgets
- **CommonButton**: Reusable button with loading states
- **CommonTextField**: Standardized text input
- **CommonOtpField**: OTP input with auto-focus
- **CommonBadge**: Styled badges
- **CommonBottomNav**: Bottom navigation component

### ✅ Module Structure
Each module follows the same pattern:
- **models/**: Data models
- **providers/**: State management
- **screens/**: UI screens
- **services/**: Business logic
- **widgets/**: Module-specific widgets

### ✅ Provider Pattern
- Centralized state management
- Reactive UI updates
- Clean separation of concerns

## 🛠 Usage

### Navigation
```dart
// Push new route
context.router.push(const LoginRoute());

// Replace current route
context.router.pushAndClearStack(const HomeRoute());

// Pop current route
context.router.pop();
```

### Common Widgets
```dart
// Button
CommonButton(
  text: 'Login',
  isLoading: isLoading,
  onPressed: () => _login(),
)

// Text Field
CommonTextField(
  controller: controller,
  hintText: 'Email',
  validator: (value) => value?.isEmpty == true ? 'Required' : null,
)

// OTP Field
CommonOtpField(
  onCompleted: (otp) => _verifyOtp(otp),
)
```

## 📦 Dependencies
- **auto_route**: Type-safe navigation
- **provider**: State management
- **flutter_screenutil**: Responsive design
- **build_runner**: Code generation

## 🔧 Development Commands
```bash
# Get dependencies
flutter pub get

# Generate routes
dart run build_runner build

# Watch for changes
dart run build_runner watch

# Clean build
dart run build_runner clean
```