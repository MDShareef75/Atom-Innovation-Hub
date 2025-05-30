# ATOM Innovation Hub

**Intelligence at the Core**

ATOM Innovation Hub is a cutting-edge platform showcasing innovative applications, insightful blog posts, and technology solutions built with Flutter and Firebase.

## 🚀 Features

- **User Authentication**: Email/password and Google sign-in options
- **Applications Showcase**: Browse and download innovative applications
- **Intelligent Blog Platform**: Read and engage with technology insights
- **Admin Dashboard**: Comprehensive management and analytics
- **Responsive Design**: Seamless experience across all devices
- **Real-time Analytics**: Track engagement and performance

## 🧬 About ATOM

ATOM represents "Intelligence at the Core" - where cutting-edge technology meets innovative solutions. Our platform is designed to foster a community of technology enthusiasts, developers, and innovators who are shaping the future.

## 🛠 Technologies Used

- **Frontend**: Flutter with Material Design 3
- **Backend**: Firebase (Authentication, Firestore, Storage, Analytics)
- **State Management**: Provider pattern
- **Navigation**: GoRouter for declarative routing
- **Data Visualization**: FL Chart for analytics
- **UI/UX**: Modern responsive design with dark theme support

## Project Structure

```
lib/
├── config/              # Configuration files
│   ├── firebase_config.dart
│   ├── router_config.dart
│   └── theme_config.dart
├── models/              # Data models
│   ├── app_model.dart
│   ├── blog_post_model.dart
│   └── user_model.dart
├── screens/             # UI screens
│   ├── admin/           # Admin dashboard
│   ├── apps/            # Apps listing and details
│   ├── auth/            # Authentication screens
│   ├── blog/            # Blog listing and post details
│   ├── profile/         # User profile
│   └── home_screen.dart # Main home screen
├── services/            # Firebase services
│   ├── analytics_service.dart
│   ├── app_service.dart
│   ├── auth_service.dart
│   └── blog_service.dart
└── main.dart            # Entry point
```

## Getting Started

### Prerequisites

- Flutter SDK
- Firebase project
- Android Studio or VS Code

### Installation

1. Clone the repository:
   ```
   git clone https://github.com/your-username/atoms_innovation_hub.git
   ```

2. Navigate to the project directory:
   ```
   cd atoms_innovation_hub
   ```

3. Install dependencies:
   ```
   flutter pub get
   ```

4. Update Firebase configuration:
   - Replace the placeholder values in `lib/config/firebase_config.dart` with your Firebase project details

5. Run the app:
   ```
   flutter run
   ```

## Firebase Setup

1. Create a new Firebase project at [console.firebase.google.com](https://console.firebase.google.com/)
2. Enable Authentication (Email/Password and Google Sign-In)
3. Create Firestore Database with the following collections:
   - users
   - applications
   - blog_posts
4. Enable Firebase Storage for image uploads
5. Configure Firebase Analytics

## Directory Structure

### Assets

- `assets/images/` - Image assets
- `assets/icons/` - Icon assets
- `assets/fonts/` - Font files

## License

MIT License - See [LICENSE](LICENSE) file for details

## Copyright & Legal

© 2025 ATOM Innovation Hub. All rights reserved.

ATOM logo and "Intelligence at the Core" are trademarks of ATOM Innovation Hub. All product names, logos, and brands are property of their respective owners.

This platform is designed to showcase innovation and foster technology community engagement.

## Contact

ATOM Innovation Hub - Intelligence at the Core  
Email: [contact@atomhub.com](mailto:contact@atomhub.com)

Project Link: [https://atoms-innovation-hub-5fbd0.web.app](https://atoms-innovation-hub-5fbd0.web.app)
