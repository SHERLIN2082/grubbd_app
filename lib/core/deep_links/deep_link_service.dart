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
    final baseUrl = savedBaseUrl.isEmpty ? Uri.base.origin : savedBaseUrl;
    final baseUri = Uri.parse(baseUrl);

    return baseUri
        .replace(queryParameters: {'roomCode': roomCode.toUpperCase()})
        .toString();
  }
}
