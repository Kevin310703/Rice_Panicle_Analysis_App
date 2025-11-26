import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:rice_panicle_analysis_app/models/supabase_user_profile.dart';

class UserSupabaseService {
  static SupabaseClient get _client => Supabase.instance.client;
  static const String _table = 'users';

  static final String? _serviceRoleKey = dotenv.env['SUPABASE_SERVICE_ROLE_KEY'];
  static SupabaseClient? _serviceClient;

  static SupabaseClient get _writer {
    if (_serviceRoleKey != null && _serviceRoleKey!.isNotEmpty) {
      return _serviceClient ??= SupabaseClient(
        dotenv.env['SUPABASE_URL']!,
        _serviceRoleKey!,
      );
    }
    return _client;
  }

  static Future<Map<String, dynamic>?> _selectWithFallback(
    Future<Map<String, dynamic>?> Function(SupabaseClient client) runner,
  ) async {
    try {
      return await runner(_client);
    } on PostgrestException catch (_) {
      if (_serviceRoleKey != null && _serviceRoleKey!.isNotEmpty) {
        return await runner(_writer);
      }
      rethrow;
    }
  }

  static Future<SupabaseUserProfile?> upsertProfile(
    SupabaseUserProfile profile,
  ) async {
    final data = await _writer
        .from(_table)
        .upsert(
          profile.toInsertMap(),
          onConflict: 'email',
        )
        .select()
        .maybeSingle();

    if (data == null) return null;
    return SupabaseUserProfile.fromMap(data);
  }

  static Future<SupabaseUserProfile?> fetchProfileByEmail(String email) async {
    final data = await _selectWithFallback(
      (client) => client
          .from(_table)
          .select()
          .eq('email', email)
          .maybeSingle(),
    );
    if (data == null) return null;
    return SupabaseUserProfile.fromMap(data);
  }

  static Future<SupabaseUserProfile?> fetchProfileById(String id) async {
    final data = await _selectWithFallback(
      (client) => client
          .from(_table)
          .select()
          .eq('id', id)
          .maybeSingle(),
    );
    if (data == null) return null;
    return SupabaseUserProfile.fromMap(data);
  }

  static Future<SupabaseUserProfile?> updateProfile({
    required String id,
    String? fullName,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? gender,
    String? address,
    String? imageProfileUrl,
  }) async {
    final payload = <String, dynamic>{};

    void addIfNotNull(String key, dynamic value) {
      if (value != null) payload[key] = value;
    }

    addIfNotNull('full_name', fullName);
    addIfNotNull('phone_number', phoneNumber);
    addIfNotNull('date_of_birth', dateOfBirth?.toIso8601String());
    addIfNotNull('gender', gender);
    addIfNotNull('address', address);
    addIfNotNull('image_profile_url', imageProfileUrl);

    if (payload.isEmpty) {
      return fetchProfileById(id);
    }

    payload['updated_at'] = DateTime.now().toIso8601String();

    final data = await _writer
        .from(_table)
        .update(payload)
        .eq('id', id)
        .select()
        .maybeSingle();

    if (data == null) return null;
    return SupabaseUserProfile.fromMap(data);
  }

  static Future<void> updatePasswordHash({
    required String id,
    required String passwordHash,
  }) async {
    await _writer.from(_table).update({
      'password_hash': passwordHash,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  static Future<void> removeProfileImage(String id) async {
    await _writer.from(_table).update({
      'image_profile_url': null,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }
}
