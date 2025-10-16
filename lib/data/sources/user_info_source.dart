import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseUserInfoSource {
  final supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> getUserInfo() async {
    final response = await supabase.from('profiles').select().single();

    return response;
  }

  Future<void> updatePinnedAp(int anchorPointId) async {
    await supabase
        .from('profiles')
        .update({'pinned_anchor_point': anchorPointId})
        .eq("user_id", supabase.auth.currentUser!.id);
  }
}
