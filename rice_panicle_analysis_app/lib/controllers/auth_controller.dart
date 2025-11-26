import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:rice_panicle_analysis_app/models/supabase_user_profile.dart';
import 'package:rice_panicle_analysis_app/services/supabase_auth_service.dart';
import 'package:rice_panicle_analysis_app/services/user_supabase_service.dart';

class AuthController extends GetxController {
  final _storage = GetStorage();

  final RxBool _isLoggedIn = false.obs;
  final RxBool _isFirstTime = true.obs;
  final Rx<User?> _user = Rx<User?>(null);
  final RxBool _isLoading = false.obs;
  final Rx<SupabaseUserProfile?> _profile = Rx<SupabaseUserProfile?>(null);
  Future<void>? _profileReadyFuture = Future<void>.value();

  bool get isLoggedIn => _isLoggedIn.value;
  bool get isFirstTime => _isFirstTime.value;
  User? get user => _user.value;
  bool get isLoading => _isLoading.value;
  String? get userEmail => _user.value?.email;
  String? get userDisplayName =>
      _profile.value?.fullName ?? _user.value?.userMetadata?['full_name'];
  SupabaseUserProfile? get userProfile => _profile.value;
  String? get userName => userDisplayName ?? userEmail;
  String? get userPhone => _profile.value?.phoneNumber;
  String? get userAddress => _profile.value?.address;
  String? get userProfileImageUrl => _profile.value?.imageProfileUrl;
  Future<void> get profileReady => _profileReadyFuture ?? Future.value();
  Rx<User?> get userChanges => _user;
  Rx<SupabaseUserProfile?> get profileChanges => _profile;

  @override
  void onInit() {
    super.onInit();
    _loadInitialState();
    _listenToAuthChanges();
  }

  void _loadInitialState() {
    _isFirstTime.value = _storage.read('isFirstTime') ?? true;
    _isLoggedIn.value = _storage.read('isLoggedIn') ?? false;
    _user.value = SupabaseAuthService.currentUser;
    _isLoggedIn.value = _user.value != null;

    if (_user.value != null) {
      _loadUserProfile(_user.value!);
    } else {
      _profileReadyFuture = Future<void>.value();
    }
  }

  Future<void> _loadUserProfile(User user) {
    final future = _performProfileLoad(user);
    _profileReadyFuture = future;
    return future;
  }

  Future<void> _performProfileLoad(User user) async {
    if (user.email == null) {
      _profile.value = null;
      return;
    }
    try {
      final profile = await UserSupabaseService.fetchProfileByEmail(
        user.email!,
      );
      _profile.value = profile;
    } catch (e) {
      _profile.value = null;
    }
  }

  void _listenToAuthChanges() {
    SupabaseAuthService.authStateChanges.listen((AuthState authState) {
      final currentUser = authState.session?.user;
      _user.value = currentUser;
      _isLoggedIn.value = currentUser != null;

      if (currentUser != null) {
        _loadUserProfile(currentUser);
      } else {
        _profile.value = null;
        _profileReadyFuture = Future<void>.value();
      }
    });
  }

  void setFirstTimeDone() {
    _isFirstTime.value = false;
    _storage.write('isFirstTime', false);
  }

  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    _isLoading.value = true;
    try {
      final result = await SupabaseAuthService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
      );

      if (result.success && result.user != null) {
        await Future.delayed(const Duration(milliseconds: 300));
        await _loadUserProfile(result.user!);
        _storage.write('isLoggedIn', true);
      } else {
        _profileReadyFuture = Future<void>.value();
      }

      return result;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading.value = true;
    try {
      final result = await SupabaseAuthService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.success && result.user != null) {
        await _loadUserProfile(result.user!);
        _storage.write('isLoggedIn', true);
      } else {
        _profileReadyFuture = Future<void>.value();
      }

      return result;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<AuthResult> resendVerification(String email) async {
    _isLoading.value = true;
    try {
      final result = await SupabaseAuthService.resendVerificationEmail(
        email: email,
      );
      return result;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<AuthResult> sendPasswordResetEmail(String email) async {
    _isLoading.value = true;
    try {
      return await SupabaseAuthService.sendPasswordResetEmail(email);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading.value = true;
    try {
      final result = await SupabaseAuthService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      return result;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<AuthResult> signOut() async {
    _isLoading.value = true;
    try {
      final result = await SupabaseAuthService.signOut();
      if (result.success) {
        _profile.value = null;
        _user.value = null;
        _profileReadyFuture = Future<void>.value();
        _storage.write('isLoggedIn', false);
      }
      return result;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> updatedUserProfile({
    String? name,
    String? phoneNumber,
    String? dateOfBirth,
    String? profileImageUrl,
    String? gender,
    String? address,
  }) async {
    final profile = _profile.value;
    if (profile == null || profile.id == null) return false;

    _isLoading.value = true;
    try {
      final parsedDob = dateOfBirth != null
          ? DateTime.tryParse(dateOfBirth)
          : null;
      final updated = await UserSupabaseService.updateProfile(
        id: profile.id ?? '',
        fullName: name,
        phoneNumber: phoneNumber,
        dateOfBirth: parsedDob,
        gender: gender,
        address: address,
        imageProfileUrl: profileImageUrl,
      );

      if (updated != null) {
        _profile.value = updated;
        return true;
      }

      return false;
    } finally {
      _isLoading.value = false;
    }
  }
}
