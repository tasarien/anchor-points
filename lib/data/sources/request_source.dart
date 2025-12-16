import 'package:anchor_point_app/data/models/request_model.dart';
import 'package:anchor_point_app/data/sources/anchor_point_source.dart';
import 'package:anchor_point_app/presentations/screens/crafting_screen.dart';
import 'package:flutter/material.dart';
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

  Future<List<Map<String, dynamic>>> getRequestsForUser(String userId) async {
    final response = await supabase
        .from('requests')
        .select()
        .or('text_requester_id.eq.$userId,audio_requester_id.eq.$userId')
        .order('created_at');
    debugPrint('req1');
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
    required HalfRequestModel textRequest,
    required HalfRequestModel audioRequest,
    required Map<String, dynamic> requestBody,
  }) async {
    requestBody['anchor_point_id'] = anchorPointId;
    requestBody['text_request'] = textRequest.toJson();
    requestBody['audio_request'] = audioRequest.toJson();
    requestBody['text_requester_id'] = textRequest.companionId;
    requestBody['audio_requester_id'] = audioRequest.companionId;

    Map<String, dynamic> request = requestBody;

    final result = await supabase
        .from('requests')
        .insert(request)
        .select()
        .single();
    int requestId = result['id'];

    await SupabaseAnchorPointSource().updateAnchorPoint(anchorPointId, {
      'request_id': requestId,
    });
  }
}
