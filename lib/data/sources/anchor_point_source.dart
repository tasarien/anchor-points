import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAnchorPointSource {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getAllAnchorPoints() async {
    final response = await supabase
        .from('anchorPoints')
        .select();

    return response;
  }
}
