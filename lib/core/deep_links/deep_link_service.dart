import 'package:flutter/foundation.dart';

class DeepLinkService {
  static String? getRoomCode() {
    final roomCode = Uri.base.queryParameters['roomCode'];

    if (roomCode == null) {
      return null;
    }

    final cleanCode = roomCode.trim().toUpperCase();
    if (!RegExp(r'^[A-Z0-9]{5}$').hasMatch(cleanCode)) {
      return null;
    }

    return cleanCode;
  }

  static String createInviteLink(String roomCode) {
    const savedBaseUrl = String.fromEnvironment('SHARE_BASE_URL');
    final cleanCode = roomCode.trim().toUpperCase();

    // Use the supplied website when the app has a public domain.
    if (savedBaseUrl.isNotEmpty) {
      return Uri.parse(
        savedBaseUrl,
      ).replace(queryParameters: {'roomCode': cleanCode}).toString();
    }

    // Chrome can share its current website address.
    if (kIsWeb) {
      return Uri.base
          .replace(queryParameters: {'roomCode': cleanCode})
          .toString();
    }

    // Android and iOS use the Grubbd application link.
    return Uri(
      scheme: 'grubbd',
      host: 'join',
      queryParameters: {'roomCode': cleanCode},
    ).toString();
  }
}
