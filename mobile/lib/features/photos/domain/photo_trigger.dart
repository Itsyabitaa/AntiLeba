enum PhotoTrigger {
  simReplacement('SIM_REPLACEMENT'),
  remoteCommand('REMOTE_COMMAND'),
  unlockFailure('UNLOCK_FAILURE'),
  manual('MANUAL');

  const PhotoTrigger(this.apiValue);

  final String apiValue;
}
