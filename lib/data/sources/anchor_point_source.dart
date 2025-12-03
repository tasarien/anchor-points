import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAnchorPointSource {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getAllAnchorPoints() async {
    final response = await supabase
        .from('anchorPoints')
        .select()
        .eq('owner_id', supabase.auth.currentUser!.id)
        .order('created_at', ascending: true);

    return response;
  }

  Future<void> deleteAnchorPoint(int anchorPointId) async {
    await supabase.from('anchorPoints').delete().eq('id', anchorPointId);
  }

  Future<void> updateAnchorPoint(
    int anchorPointId,
    Map<String, dynamic> updatedRows,
  ) async {
    await supabase
        .from('anchorPoints')
        .update(updatedRows)
        .eq('id', anchorPointId);
  }
}
