import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rice_panicle_analysis_app/services/firebase_auth_service.dart';
import 'package:rice_panicle_analysis_app/services/firestore_service.dart';

class AuthController extends GetxController {
  final _storage = GetStorage();

  final RxBool _isLoggedIn = false.obs;
  final RxBool _isFirstTime = true.obs;
  final Rx<User?> _user = Rx<User?>(null);
  final RxBool _isLoading = false.obs;
  final Rx<Map<String, dynamic>?> _userDocument = Rx<Map<String, dynamic>?>(
    null,
  );

  bool get isLoggedIn => _isLoggedIn.value;
  bool get isFirstTime => _isFirstTime.value;
  User? get user => _user.value;
  bool get isLoading => _isLoading.value;
  String? get userEmail => _user.value?.email;
  String? get userDisplayName => _user.value?.displayName;
  Map<String, dynamic>? get userDocument => _userDocument.value;
  String? get userName =>
      _userDocument.value?['name'] ?? _user.value?.displayName;
  String? get userPhone => _userDocument.value?['phoneNumber'];
  String? get userAddress => _userDocument.value?['phoneNumber'];
  Map<String, dynamic> get userPreferences =>
      _userDocument.value?['preferences'];

  @override
  void onInit() {
    super.onInit();
    _loadInitialState();
    _listenToAuthChanges();
  }

  void _loadInitialState() {
    _isLoggedIn.value = _storage.read('isLoggedIn') ?? false;
    // Check Firebase auth state instead of local storage
    // _isFirstTime.value = _storage.read('isFirstTime') ?? true;

    _user.value = FirebaseAuthService.currentUser;
    _isLoggedIn.value = FirebaseAuthService.isSignedIn;

    // Load user document if user is already signed in
    if (_user.value != null) _loadUserDocument(_user.value!.uid);
  }

  // Load user document from Firestore
  Future<void> _loadUserDocument(String uid) async {
    try {
      final userDoc = await FirestoreService.getUserDocument(uid);
      _userDocument.value = userDoc;
    } catch (e) {
      print('Error loading user document: $e');
    }
  }

  void _listenToAuthChanges() {
    FirebaseAuthService.authStateChanges.listen((User? user) {
      _user.value = user;
      _isLoggedIn.value = user != null;

      if (user != null) {
        // Load user document fro, Firestore
        _loadUserDocument(user.uid);
      } else {
        // Clear user document when signed out
        _userDocument.value = null;
      }
    });
  }

  void setFirstTimeDone() {
    _isFirstTime.value = false;
    _storage.write('isFirstTime', false);
  }

  // Sign up with email and password
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    _isLoading.value = true;
    try {
      final result = await FirebaseAuthService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
      );

      // If sign-up is successful, load user document immadiately
      if (result.success && result.user != null) {
        // Add a small delay to ensure Firestore document is fully created
        await Future.delayed(const Duration(milliseconds: 500));
        await _loadUserDocument(result.user!.uid);
      }

      return result;
    } finally {
      _isLoading.value = false;
    }
  }

  // Sign in with email and password
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading.value = true;
    try {
      final result = await FirebaseAuthService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // If sign-in is successful, load user document immadiately
      if (result.success && result.user != null) {
        await _loadUserDocument(result.user!.uid);
      }

      return result;
    } finally {
      _isLoading.value = false;
    }
  }

  // Send password reset email
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    _isLoading.value = true;
    try {
      final result = await FirebaseAuthService.sendPasswordResetEmail(email);

      return result;
    } finally {
      _isLoading.value = false;
    }
  }

  // Sign out
  Future<AuthResult> signOut() async {
    _isLoading.value = true;
    try {
      final result = await FirebaseAuthService.signOut();
      return result;
    } finally {
      _isLoading.value = false;
    }
  }

  // Update user profile in Firestore
  Future<bool> updatedUserProfile({
    String? name,
    String? phoneNumber,
    String? dateOfBirth,
    String? profileImageUrl,
    String? gender,
    String? address,
  }) async {
    if (_user.value == null) return false;

    _isLoading.value = true;
    try {
      final success = await FirestoreService.updatedUserProfile(
        uid: _user.value!.uid,
        name: name,
        phoneNumber: phoneNumber,
        dateOfBirth: dateOfBirth,
        gender: gender,
        profileImageUrl: profileImageUrl,
        address: address,
      );

      if (success) {
        // Reload user document to get updated data
        await _loadUserDocument(_user.value!.uid);
      }

      return success;
    } finally {
      _isLoading.value = false;
    }
  }

  // Update user preferences
  Future<bool> updatedUserPreferences(Map<String, dynamic> preferences) async {
    if (_user.value == null) return false;

    _isLoading.value = true;
    try {
      final success = await FirestoreService.updateUserPreferences(
        uid: _user.value!.uid,
        preferences: preferences,
      );

      if (success) {
        // Reload user document to get updated data
        await _loadUserDocument(_user.value!.uid);
      }

      return success;
    } finally {
      _isLoading.value = false;
    }
  }
}
