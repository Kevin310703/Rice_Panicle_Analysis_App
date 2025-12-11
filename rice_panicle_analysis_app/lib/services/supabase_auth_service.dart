import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:rice_panicle_analysis_app/models/supabase_user_profile.dart';
import 'package:rice_panicle_analysis_app/services/user_supabase_service.dart';

class SupabaseAuthService {
  static SupabaseClient get _client => Supabase.instance.client;
  static const String _profileBucket = 'images';
  static const String _profileFolder = 'avatar';
  static String get _authRedirectUri => kIsWeb
      ? '${Uri.base.origin}/auth/callback'
      : 'io.supabase.flutterquickstart://login-callback/';

  static User? get currentUser => _client.auth.currentUser;
  static Stream<AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;

  static Future<AuthResult> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    String? phoneNumber,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
        emailRedirectTo: _authRedirectUri,
      );

      final session = response.session;
      final user = response.user ?? session?.user;
      final needsVerification =
          session == null || (user?.emailConfirmedAt == null);

      if (user != null) {
        await _ensureProfileRecord(
          user: user,
          password: password,
          fullName: name,
          phoneNumber: phoneNumber,
        );
      }

      return AuthResult(
        needsVerification,
        success: true,
        user: needsVerification ? null : user,
        message: needsVerification
            ? 'Đăng ký thành công. Vui lòng kiểm tra email để xác nhận tài khoản.'
            : 'Tạo tài khoản thành công.',
      );
    } on AuthException catch (e) {
      return AuthResult(false, success: false, message: e.message);
    } catch (e) {
      return AuthResult(
        false,
        success: false,
        message: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  static Future<AuthResult> resendVerificationEmail({String? email}) async {
    try {
      final userEmail = email ?? currentUser?.email;
      if (userEmail == null) {
        return AuthResult(
          true,
          success: false,
          message: 'Không tìm thấy địa chỉ email.',
        );
      }

        await _client.auth.resend(
          type: OtpType.signup,
          email: userEmail,
          emailRedirectTo: _authRedirectUri,
        );

      return AuthResult(
        true,
        success: true,
        message: 'Đã gửi lại email xác nhận đến $userEmail',
      );
    } on AuthException catch (e) {
      return AuthResult(
        true,
        success: false,
        message: 'Không thể gửi email xác nhận: ${e.message}',
      );
    } catch (e) {
      return AuthResult(
        true,
        success: false,
        message: 'Không thể gửi email xác nhận. Vui lòng thử lại.',
      );
    }
  }

  static Future<bool> isEmailVerified() async {
    try {
      final user = currentUser;
      if (user == null) return false;

      final response = await _client.auth.refreshSession();
      final refreshedUser = response.user;
      return refreshedUser?.emailConfirmedAt != null;
    } catch (e) {
      debugPrint('Error checking verification status: $e');
      return false;
    }
  }

  static Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user ?? response.session?.user;
      if (user != null) {
        await _ensureProfileRecord(
          user: user,
          password: password,
          fullName: _extractFullName(user),
        );
      }

      return AuthResult(
        false,
        success: true,
        user: user,
        message: 'Đăng nhập thành công',
      );
    } on AuthException catch (e) {
      return AuthResult(false, success: false, message: e.message);
    } catch (e) {
      return AuthResult(
        false,
        success: false,
        message: 'Đăng nhập thất bại. Vui lòng thử lại.',
      );
    }
  }

  static Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: _authRedirectUri,
      );
      return AuthResult(
        false,
        success: true,
        message: 'Password reset instructions sent to $email',
      );
    } on AuthException catch (e) {
      return AuthResult(false, success: false, message: e.message);
    } catch (e) {
      return AuthResult(
        false,
        success: false,
        message: 'Unable to send password reset email.',
      );
    }
  }

  static Future<AuthResult> completePasswordRecovery(
    String newPassword,
  ) async {
    final user = currentUser;
    if (user == null || user.email == null) {
      return AuthResult(
        false,
        success: false,
        message: 'Recovery session expired. Please request a new email.',
      );
    }

    try {
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      final profile =
          await UserSupabaseService.fetchProfileByEmail(user.email!);
      if (profile != null && profile.id != null) {
        await UserSupabaseService.updatePasswordHash(
          id: profile.id!,
          passwordHash: _hashPassword(user.id, newPassword),
        );
      }

      return AuthResult(
        false,
        success: true,
        message: 'Password has been reset successfully.',
      );
    } on AuthException catch (e) {
      return AuthResult(false, success: false, message: e.message);
    } catch (e) {
      return AuthResult(
        false,
        success: false,
        message: 'Unable to reset password. Please try again.',
      );
    }
  }

  static Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = currentUser;
    if (user == null || user.email == null) {
      return AuthResult(
        false,
        success: false,
        message: 'Bạn chưa đăng nhập.',
      );
    }

    try {
      await _client.auth.signInWithPassword(
        email: user.email!,
        password: currentPassword,
      );

      await _client.auth.updateUser(UserAttributes(password: newPassword));

      final profile =
          await UserSupabaseService.fetchProfileByEmail(user.email!);
      if (profile != null && profile.id != null) {
        await UserSupabaseService.updatePasswordHash(
          id: profile.id!,
          passwordHash: _hashPassword(user.id, newPassword),
        );
      }

      return AuthResult(
        false,
        success: true,
        message: 'Đổi mật khẩu thành công',
      );
    } on AuthException catch (e) {
      return AuthResult(false, success: false, message: e.message);
    } catch (e) {
      return AuthResult(
        false,
        success: false,
        message: 'Không thể đổi mật khẩu. Vui lòng thử lại.',
      );
    }
  }

  static Future<AuthResult> signOut() async {
    try {
      await _client.auth.signOut();
      return AuthResult(
        false,
        success: true,
        message: 'Đăng xuất thành công',
      );
    } on AuthException catch (e) {
      return AuthResult(false, success: false, message: e.message);
    } catch (e) {
      return AuthResult(
        false,
        success: false,
        message: 'Không thể đăng xuất. Vui lòng thử lại.',
      );
    }
  }

  static Future<Map<String, dynamic>> uploadProfileImage({
    required XFile imageFile,
    required String profileId,
  }) async {
    final user = currentUser;
    if (user == null) {
      return {
        'success': false,
        'message': 'Bạn cần đăng nhập để tải ảnh.',
      };
    }

    try {
      final bucket = _client.storage.from(_profileBucket);
      final extension = _extensionOf(imageFile.name);
      final fileName = '${_profileFolder}/profile_${user.id}.$extension';
      final bytes = await imageFile.readAsBytes();

      await bucket.uploadBinary(
        fileName,
        bytes,
        fileOptions: FileOptions(
          upsert: true,
          contentType: _contentTypeForExt(extension),
        ),
      );

      final publicUrl = bucket.getPublicUrl(fileName);

      await UserSupabaseService.updateProfile(
        id: profileId,
        imageProfileUrl: publicUrl,
      );

      return {
        'success': true,
        'imageUrl': publicUrl,
        'message': 'Tải ảnh thành công',
      };
    } on StorageException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {
        'success': false,
        'message': 'Không thể tải ảnh. Vui lòng thử lại.',
      };
    }
  }

  static Future<bool> deleteProfileImage({
    required String profileId,
    required String imageUrl,
  }) async {
    if (imageUrl.isEmpty) return false;

    try {
      final path = _storagePathFromUrl(imageUrl);
      if (path != null) {
        await _client.storage.from(_profileBucket).remove([path]);
      }

      await UserSupabaseService.removeProfileImage(profileId);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> _ensureProfileRecord({
    required User user,
    required String password,
    String? fullName,
    String? phoneNumber,
  }) async {
    try {
      final email = user.email;
      if (email == null) return;

      final existing = await UserSupabaseService.fetchProfileByEmail(email);
      if (existing != null) return;

      final metadataName = _extractFullName(user);
      final resolvedName = (fullName?.trim().isNotEmpty == true
              ? fullName!.trim()
              : metadataName)
          ?.trim();

      final fallbackName =
          resolvedName?.isNotEmpty == true ? resolvedName! : email.split('@').first;

      final profile = SupabaseUserProfile(
        id: user.id,
        username: _buildUsername(fallbackName, email),
        passwordHash: _hashPassword(user.id, password),
        fullName: fallbackName,
        email: email,
        phoneNumber: phoneNumber,
        imageProfileUrl: 'https://oddqjpyrvytrjazqpyey.supabase.co/storage/v1/object/public/images/default/avatar.png',
        isActive: true,
        createdAt: DateTime.now(),
      );

      await UserSupabaseService.upsertProfile(profile);
    } on PostgrestException catch (e) {
      debugPrint(
        'Warning: unable to create profile row (${e.message}). '
        'Ensure RLS policies allow authenticated inserts or provide SUPABASE_SERVICE_ROLE_KEY.',
      );
    } catch (e) {
      debugPrint('Warning: unable to create profile row: $e');
    }
  }

  static String? _extractFullName(User user) {
    final metadata = user.userMetadata;
    if (metadata is Map<String, dynamic>) {
      final value = metadata['full_name'];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  static String _hashPassword(String userId, String password) {
    final salted = '$userId::$password';
    final bytes = utf8.encode(salted);
    return sha256.convert(bytes).toString();
  }

  static String _buildUsername(String name, String email) {
    final sanitized = name.trim().isNotEmpty ? name.trim() : email.split('@').first;
    return sanitized.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');
  }

  static String _extensionOf(String name) {
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex == -1) return 'jpg';
    return name.substring(dotIndex + 1).toLowerCase();
  }

  static String _contentTypeForExt(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  static String? _storagePathFromUrl(String url) {
    if (url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final segments = uri.pathSegments;
    final bucketIndex = segments.indexOf(_profileBucket);
    if (bucketIndex == -1 || bucketIndex + 1 >= segments.length) return null;
    final relativeSegments = segments.sublist(bucketIndex + 1);
    if (relativeSegments.isEmpty) return null;
    return relativeSegments.join('/');
  }
}

class AuthResult {
  final bool needsEmailVerification;
  final bool success;
  final User? user;
  final String message;

  const AuthResult(
    this.needsEmailVerification, {
    required this.success,
    this.user,
    required this.message,
  });

  @override
  String toString() =>
      'AuthResult(success: $success, needsVerification: $needsEmailVerification, message: $message)';
}
