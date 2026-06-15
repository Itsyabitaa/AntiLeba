class SmsSendResult {
  const SmsSendResult({
    required this.sent,
    required this.queued,
    required this.skipped,
    required this.remaining,
    this.error,
  });

  const SmsSendResult.idle()
      : sent = 0,
        queued = 0,
        skipped = 0,
        remaining = 0,
        error = null;

  final int sent;
  final int queued;
  final int skipped;
  final int remaining;
  final String? error;

  bool get hadWork => sent > 0 || skipped > 0;
}
