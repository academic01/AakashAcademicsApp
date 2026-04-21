# Aakash Academics Flutter App

## 📚 Project Overview

Aakash Academics is a comprehensive coaching app designed for:
- **Classes 6-12**: School curriculum coaching
- **CUET 2026**: New batch starting April 2026
- **Government Jobs**: SSC, Railway, DSSSB preparation
- **JEE & NEET**: Coming soon

## 📁 Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   ├── colors.dart              # App color palette
│   │   ├── text_styles.dart         # Text style definitions
│   │   └── app_constants.dart       # App-wide constants
│   ├── theme/
│   │   └── app_theme.dart           # Complete theme configuration
│   └── utils/
│       └── validators.dart          # Input validation functions
├── data/
│   ├── models/
│   │   ├── user_model.dart          # User data model
│   │   ├── course_model.dart        # Course data model
│   │   └── test_model.dart          # Test data model
│   └── services/
│       ├── api_service.dart         # HTTP client service
│       ├── auth_service.dart        # Authentication service
│       └── storage_service.dart     # Local storage service
├── presentation/
│   ├── screens/
│   │   ├── splash/
│   │   ├── onboarding/
│   │   ├── auth/
│   │   ├── home/
│   │   ├── courses/
│   │   ├── live/
│   │   ├── tests/
│   │   └── profile/
│   ├── widgets/                     # Reusable widgets
│   └── navigation/                  # Route configuration
├── providers/                       # State management
├── main.dart                        # App entry point
└── app.dart                         # App configuration

assets/
├── images/                          # Image assets
├── icons/                           # Icon assets
├── fonts/                           # Custom fonts
└── lottie/                          # Lottie animations
```

## 🎨 Design System

### Colors
- **Primary**: Navy Blue (`#0D2240`)
- **Secondary**: Orange (`#F5A623`)
- **CUET**: Purple (`#7C3AED`)
- **Government Jobs**: Green (`#16A34A`)
- **JEE**: Crimson (`#DC2626`)
- **NEET**: Cyan (`#0891B2`)

### Typography
- **Font Family**: Nunito
- **Display**: Large (32px), Medium (28px), Small (24px)
- **Headline**: Large (22px), Medium (20px), Small (18px)
- **Body**: Large (16px), Medium (14px), Small (12px)

## 🚀 Getting Started

### Prerequisites
- Flutter 3.0+
- Dart 3.0+
- iOS 11.0+ or Android 5.0+

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd aakash_academics
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate build files** (if needed)
   ```bash
   flutter pub run build_runner build
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## 📦 Dependencies

Key packages used:
- `provider`: State management
- `http`: HTTP client
- `shared_preferences`: Local storage
- `firebase_core`: Firebase initialization (when configured)
- `lottie`: Animations
- `google_fonts`: Font management

## 🏗️ Architecture

This project follows **Clean Architecture** principles:

- **data/**: Database, API, and local storage implementation
- **presentation/**: UI screens and widgets
- **core/**: Constants, themes, and utilities
- **providers/**: State management and business logic

## 🔧 Configuration

### Firebase Setup (Optional)
1. Add `firebase_core` and required Firebase packages to `pubspec.yaml`
2. Configure Firebase in `main.dart`
3. Add `google-services.json` and `GoogleService-Info.plist`

### API Configuration
Update `ApiService.baseUrl` in `data/services/api_service.dart` with your backend URL.

## 📝 Usage Examples

### Adding a New Screen
1. Create a new file in `presentation/screens/<screen_name>/`
2. Implement the screen widget
3. Add route in `presentation/navigation/routes.dart`
4. Update navigation

### Adding a New Model
1. Create model in `data/models/`
2. Implement `toJson()` and `fromJson()` methods
3. Add `copyWith()` method for immutability

### Using Services
```dart
final authService = Provider.of<AuthService>(context, listen: false);
await authService.signIn(email: 'user@example.com', password: 'password');
```

## 🧪 Testing

To run tests:
```bash
flutter test
```

## 📱 Supported Platforms
- ✅ Android (5.0+)
- ✅ iOS (11.0+)
- 📋 Web (Coming soon)

## 🤝 Contributing

1. Create a feature branch (`git checkout -b feature/AmazingFeature`)
2. Commit your changes (`git commit -m 'Add AmazingFeature'`)
3. Push to the branch (`git push origin feature/AmazingFeature`)
4. Open a Pull Request

## 📄 License

This project is proprietary and confidential.

## 👨‍💻 Author

Aakash Academics Team

## 📞 Support

For support, email: support@aakashacademics.com

---

**Last Updated**: April 2026
