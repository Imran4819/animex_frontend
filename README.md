# Animex Billing Mobile App

An elegant, high-fidelity Flutter mobile application built for **Animex Animal Health Care Pvt. Ltd.** to manage invoices, medical store directory records, and veterinary product prices. It acts as the mobile companion to the Animex billing web dashboard.

---

## Design System & Theme

The app matches the corporate web app's style exactly:
- **Primary Navy (Gradient)**: `#0B1526` to `#101B33` (used in headers, nav bars, and buttons)
- **Primary Orange (Gradient)**: `#F5711B` to `#FF8A3D` (used in primary CTAs and active states)
- **Success Green**: `#16A34A` (badge background: `#DCFCE7`) for PAID invoices and badges
- **Warning Amber**: `#F59E0B` (badge background: `#FEF3C7`) for DUE invoices and pending items
- **Background Grey**: `#F3F5F8`
- **Typography**: clean sans-serif styles utilizing Poppins (headings) and Inter (body copy) via Google Fonts.
- **Card Aesthetics**: white surface with 12px rounded corners and smooth micro-shadows.

---

## Project Structure

The codebase is organized following clean architectural principles:

```
lib/
├── core/
│   ├── constants/
│   │   ├── api_constants.dart    # API paths, timeouts, and useMockData switch
│   │   └── color_constants.dart  # Hex values & gradients definitions
│   ├── network/
│   │   └── dio_client.dart       # Network interface + token auth headers interceptor
│   ├── router/
│   │   └── router.dart           # GoRouter setup + redirection rules for auth guards
│   ├── theme/
│   │   └── app_theme.dart        # Global Material theme config and fonts
│   └── utils/
│       └── currency_formatter.dart # Extends numbers for Indian Rupee (₹) formatting
├── features/
│   ├── auth/                     # Splash, Login (Email or Mobile), OTP entry, and Signup
│   ├── dashboard/                # Invoices totals summary cards and quick shortcuts
│   ├── bills/                    # Billing listings, detail builder, and paper-print previews
│   ├── stores/                   # Customers/dealers lists and CRUD sheet panel
│   ├── products/                 # Veterinary medicine lists sorted by category and CRUD panel
│   └── profile/                  # User profile and registered helplines
├── shared/
│   └── widgets/                  # Reusable UI widgets: buttons, badges, nav bar, and logo
└── main.dart                     # App entry bootstrapper
```

---

## Configuration & API Connection

### Centralized Endpoint Mapping
All connections to the backend API are managed through the centralized `ApiConstants` configuration file:
- **File Location**: [api_constants.dart](lib/core/constants/api_constants.dart)

To connect the app to a live or staging backend server, customize:
```dart
class ApiConstants {
  // 1. Set this to false to send real network requests
  static const bool useMockData = false;

  // 2. Point this to your backend gateway
  static const String baseUrl = 'https://api.animexanimalhealthcare.com/api/v1';
}
```

### Authentication Mechanics
1. **Verification**: When you verify your email address or mobile number with a 6-digit OTP, the app dispatches a `POST /auth/verify-otp`.
2. **Persistence**: Upon a successful request, the returned JWT string is cached inside `flutter_secure_storage` for safety.
3. **Automatic Headers**: The custom [DioClient](lib/core/network/dio_client.dart) uses an interceptor to read the cached token and injects it automatically into the headers of subsequent requests:
   ```http
   Authorization: Bearer <token>
   ```
4. **Expiry Handlers**: If the API gateway returns a `401 Unauthorized` response (due to token expiration), the client interceptor clears the secure storage and routes the user back to the login screen automatically.

---

## Getting Started

### Prerequisites
- Flutter SDK (latest stable channel)
- Dart SDK

### Installation
1. Clone the repository and navigate to the project directory:
   ```bash
   cd animex-app
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app on your connected device or emulator:
   ```bash
   flutter run
   ```

### Testing with Offline Mock Data
By default, the configuration file has `useMockData = true`. This allows you to explore every single screen, add/edit/delete stores and products, and create bills with real-time math calculations without requiring a live server!

- **OTP Verification Bypass**: On the OTP entry screen, enter **`123456`** (or any 6 digits) to successfully log in and access the dashboard.
