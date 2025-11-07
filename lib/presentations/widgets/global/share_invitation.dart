import 'package:share_plus/share_plus.dart';

/// Shares an invitation to the app via email, messaging apps, and others.
///
/// [request] should contain keys such as:
/// {
///   'title': 'Invite to MyApp',
///   'message': 'Hey! Check out this awesome app!',
///   'link': 'https://myapp.com/invite?code=12345'
/// }
Future<void> shareAppInvitation(Map<String, dynamic> request) async {
  try {
    // Extract values safely
    final String title = request['title'] ?? 'Invite to our app';
    final String message = request['message'] ?? 'Join me on this amazing app!';
    final String link = request['link'] ?? '';

    // Construct the full share text
    final String shareText = '$message\n\n$link';

    // Use share_plus to open native share options
    await Share.share(
      shareText,
      subject: title, // Used by some apps like email
    );
  } catch (e) {
    // You can log or handle the error appropriately
    print('Error sharing invitation: $e');
  }
}
