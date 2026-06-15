enum RemoteCommandType {
  activateTheftMode('ACTIVATE_THEFT_MODE'),
  requestLiveLocation('REQUEST_LIVE_LOCATION'),
  triggerAlarm('TRIGGER_ALARM'),
  captureImage('CAPTURE_IMAGE');

  const RemoteCommandType(this.apiValue);

  final String apiValue;

  static RemoteCommandType? fromApi(String? value) {
    if (value == null) return null;
    for (final type in RemoteCommandType.values) {
      if (type.apiValue == value) return type;
    }
    return null;
  }
}
