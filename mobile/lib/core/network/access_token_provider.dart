import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-memory bearer token mirrored from secure storage for Dio interceptors.
final accessTokenProvider = StateProvider<String?>((ref) => null);
