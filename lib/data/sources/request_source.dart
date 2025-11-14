import 'package:anchor_point_app/data/sources/anchor_point_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseRequestSource {
  final supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> getRequest(int id) async {
    final response = await supabase
        .from('requests')
        .select()
        .eq('id', id)
        .single();

    return response;
  }

  Future<void> deleteRequest(int requestId) async {
    await supabase.from('request').delete().eq('id', requestId);
  }

  Future<void> updateRequest(
    int requestId,
    Map<String, dynamic> updatedRows,
  ) async {
    await supabase.from('requests').update(updatedRows).eq('id', requestId);
  }

  Future<void> createRequest({
    required int anchorPointId,
    required String type,
    required Map<String, dynamic> requestBody,
  }) async {
    Map<String, dynamic> request = requestBody;
    requestBody['type'] = type;
    requestBody['anchor_point_id'] = anchorPointId;
    final result = await supabase
        .from('requests')
        .insert(request)
        .select()
        .single();
    int requestId = result['id'];
    if (type == 'text') {
      await SupabaseAnchorPointSource().updateAnchorPoint(anchorPointId, {
        'text_request_id': requestId,
      });
    } else if (type == 'audio') {
      await SupabaseAnchorPointSource().updateAnchorPoint(anchorPointId, {
        'audio_request_id': requestId,
      });
    }
  }
}
