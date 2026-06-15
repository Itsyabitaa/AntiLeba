class SyncResult {
  const SyncResult({
    required this.uploaded,
    required this.skipped,
    required this.remaining,
  });

  const SyncResult.idle()
      : uploaded = 0,
        skipped = 0,
        remaining = 0;

  final int uploaded;
  final int skipped;
  final int remaining;

  bool get hadWork => uploaded > 0 || skipped > 0;
}
