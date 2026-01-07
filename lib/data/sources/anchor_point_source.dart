import 'dart:io';

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

  Future<Map<String, dynamic>> getAnchorPoint(int anchorPointId) async {
    final response = await supabase
        .from('anchorPoints')
        .select()
        .eq('id', anchorPointId)
        .single();

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

  Future<String> uploadAudioFile(
    String filePath,
    String folderName,
    String fileName,
  ) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final userId = supabase.auth.currentUser!.id;
      final storagePath = '$userId/$folderName/$fileName.m4a';

      await supabase.storage
          .from('anchor-points-audio')
          .uploadBinary(storagePath, bytes);

      final publicUrl = supabase.storage
          .from('anchor-points-audio')
          .getPublicUrl(storagePath);

      return publicUrl;
    } on SocketException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to upload audio: $e');
    }
  }
}
