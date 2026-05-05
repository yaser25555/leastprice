class PendingAuthSession {
  const PendingAuthSession._();

  static String? _inviteCode;

  static void setInviteCode(String rawInviteCode) {
    final normalized = rawInviteCode.trim().toUpperCase();
    _inviteCode = normalized.isEmpty ? null : normalized;
  }

  static String? consumeInviteCode() {
    final value = _inviteCode;
    _inviteCode = null;
    return value;
  }
}
