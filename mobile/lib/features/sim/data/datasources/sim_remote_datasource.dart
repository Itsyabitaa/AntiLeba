import 'package:dio/dio.dart';

import 'package:anti_leba/features/sim/domain/sim_repository.dart';

class SimRemoteDataSource {
  SimRemoteDataSource(this._dio);

  final Dio _dio;

  Future<void> reportChange(SimChangeEvent event) async {
    await _dio.post<void>('/sim-changes', data: event.toApiJson());
  }
}
