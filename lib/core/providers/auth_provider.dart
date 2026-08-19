import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/auth_service.dart';

// Provider for SharedPreferences to be overridden in main.dart
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences has not been initialized');
});

class AuthState {
  final bool isLoading;
  final String? token;
  final String? userName;
  final String? userEmail;
  final String? userPhone;
  final String? userAddress;
  final String? userCity;
  final String? clientId;
  final String? errorMessage;

  AuthState({
    this.isLoading = false,
    this.token,
    this.userName,
    this.userEmail,
    this.userPhone,
    this.userAddress,
    this.userCity,
    this.clientId,
    this.errorMessage,
  });

  bool get isAuthenticated => token != null;

  AuthState copyWith({
    bool? isLoading,
    String? token,
    String? userName,
    String? userEmail,
    String? userPhone,
    String? userAddress,
    String? userCity,
    String? clientId,
    String? errorMessage,
    bool clearError = false,
    bool clearUserData = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      token: clearUserData ? null : (token ?? this.token),
      userName: clearUserData ? null : (userName ?? this.userName),
      userEmail: clearUserData ? null : (userEmail ?? this.userEmail),
      userPhone: clearUserData ? null : (userPhone ?? this.userPhone),
      userAddress: clearUserData ? null : (userAddress ?? this.userAddress),
      userCity: clearUserData ? null : (userCity ?? this.userCity),
      clientId: clearUserData ? null : (clientId ?? this.clientId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final SharedPreferences _prefs;

  static const _keyToken = 'auth_token';
  static const _keyName = 'auth_name';
  static const _keyEmail = 'auth_email';
  static const _keyPhone = 'auth_phone';
  static const _keyAddress = 'auth_address';
  static const _keyCity = 'auth_city';
  static const _keyClientId = 'auth_client_id';

  AuthNotifier(this._authService, this._prefs) : super(AuthState()) {
    _loadSession();
  }

  void _loadSession() {
    final token = _prefs.getString(_keyToken);
    if (token != null) {
      state = AuthState(
        token: token,
        userName: _prefs.getString(_keyName),
        userEmail: _prefs.getString(_keyEmail),
        userPhone: _prefs.getString(_keyPhone),
        userAddress: _prefs.getString(_keyAddress),
        userCity: _prefs.getString(_keyCity),
        clientId: _prefs.getString(_keyClientId),
      );
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null, clearError: true);
    try {
      final response = await _authService.login(email.trim(), password.trim());
      final token = response['token'] as String;
      final clientMap = (response['client'] ?? response['user']) as Map<String, dynamic>;

      final clientId = (clientMap['client_id'] ?? clientMap['id']) as String? ?? '';
      final name = clientMap['name'] as String? ?? '';
      final userEmail = clientMap['email'] as String? ?? email;
      final phone = clientMap['phone'] as String? ?? '';
      final address = clientMap['address'] as String? ?? '';
      final city = clientMap['city'] as String? ?? '';
      // Persist values
      await _prefs.setString(_keyToken, token);
      await _prefs.setString(_keyName, name);
      await _prefs.setString(_keyEmail, userEmail);
      await _prefs.setString(_keyPhone, phone);
      await _prefs.setString(_keyAddress, address);
      await _prefs.setString(_keyCity, city);
      await _prefs.setString(_keyClientId, clientId);

      state = state.copyWith(
        isLoading: false,
        token: token,
        userName: name,
        userEmail: userEmail,
        userPhone: phone,
        userAddress: address,
        userCity: city,
        clientId: clientId,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> signup({
    required String name,
    required String email,
    required String phone,
    required String address,
    required String city,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, clearError: true);
    try {
      final response = await _authService.signup(
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        address: address.trim(),
        city: city.trim(),
      );

      // If signup returns token & client object, log in immediately
      if (response.containsKey('token') && response.containsKey('client')) {
        final token = response['token'] as String;
        final clientMap = response['client'] as Map<String, dynamic>;

        final clientId = clientMap['id'] as String? ?? '';
        final clientName = clientMap['name'] as String? ?? name;
        final clientEmail = clientMap['email'] as String? ?? email;
        final clientPhone = clientMap['phone'] as String? ?? phone;
        final clientAddress = clientMap['address'] as String? ?? address;
        final clientCity = clientMap['city'] as String? ?? city;

        await _prefs.setString(_keyToken, token);
        await _prefs.setString(_keyName, clientName);
        await _prefs.setString(_keyEmail, clientEmail);
        await _prefs.setString(_keyPhone, clientPhone);
        await _prefs.setString(_keyAddress, clientAddress);
        await _prefs.setString(_keyCity, clientCity);
        await _prefs.setString(_keyClientId, clientId);

        state = state.copyWith(
          isLoading: false,
          token: token,
          userName: clientName,
          userEmail: clientEmail,
          userPhone: clientPhone,
          userAddress: clientAddress,
          userCity: clientCity,
          clientId: clientId,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _prefs.remove(_keyToken);
    await _prefs.remove(_keyName);
    await _prefs.remove(_keyEmail);
    await _prefs.remove(_keyPhone);
    await _prefs.remove(_keyAddress);
    await _prefs.remove(_keyCity);
    await _prefs.remove(_keyClientId);
    state = AuthState();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthNotifier(authService, prefs);
});
