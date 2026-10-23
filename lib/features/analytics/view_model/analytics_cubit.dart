import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:finecho/core/models/analytics_period.dart';
import 'package:finecho/features/analytics/view_model/models/analytics_state.dart';
import 'package:finecho/features/analytics/view_model/services/analytics_service.dart';
import 'package:flutter/foundation.dart';

const String _loadErrorMessage =
    'Could not load your statistics. Please try again.';

/// Coordinates statistics dashboard state for the analytics screen.
class AnalyticsCubit extends Cubit<AnalyticsState> {
  /// Creates an analytics cubit backed by the analytics service.
  new(this._service) : super(const AnalyticsState());

  final AnalyticsService _service;
  bool _isLoading = false;
  AnalyticsPeriod? _pendingPeriod;
  Future<void>? _inFlight;

  /// Loads the dashboard for the selected period.
  ///
  /// A load requested while another one is running waits for it to settle and
  /// then reloads, so callers like pull-to-refresh observe fresh data.
  Future<void> load() async {
    while (!isClosed) {
      final inFlight = _inFlight;
      if (inFlight != null) {
        await inFlight;
        continue;
      }
      await _load(state.period);
      return;
    }
  }

  /// Selects [period] and reloads the dashboard when it changed.
  ///
  /// A selection made while a load is in flight is queued and applied as soon
  /// as the running load settles.
  Future<void> selectPeriod(AnalyticsPeriod period) async {
    if (period == state.period) {
      _pendingPeriod = null;
      return;
    }
    if (period == _pendingPeriod) {
      return;
    }
    if (_isLoading) {
      _pendingPeriod = period;
      return;
    }
    await _load(period);
  }

  Future<void> _load(AnalyticsPeriod period) {
    if (_isLoading || isClosed) {
      return _inFlight ?? Future<void>.value();
    }
    final inFlight = _runLoad(period);
    _inFlight = inFlight;
    return inFlight;
  }

  Future<void> _runLoad(AnalyticsPeriod period) async {
    _isLoading = true;
    try {
      var targetPeriod = period;
      while (!isClosed) {
        emit(
          state.copyWith(
            status: AnalyticsStatus.loading,
            period: targetPeriod,
            clearErrorMessage: true,
          ),
        );
        await _attemptLoad(targetPeriod);
        final pendingPeriod = _pendingPeriod;
        if (pendingPeriod == null) {
          break;
        }
        _pendingPeriod = null;
        targetPeriod = pendingPeriod;
      }
    } finally {
      _isLoading = false;
      _inFlight = null;
    }
  }

  Future<void> _attemptLoad(AnalyticsPeriod period) async {
    try {
      final dashboard = await _service.loadDashboard(period: period);
      if (!isClosed) {
        emit(
          AnalyticsState(
            status: AnalyticsStatus.ready,
            period: period,
            dashboard: dashboard,
          ),
        );
      }
    } on Object catch (error, stackTrace) {
      if (!isClosed) {
        if (kDebugMode) {
          log(
            'Analytics dashboard load failed',
            name: 'AnalyticsCubit',
            error: error,
            stackTrace: stackTrace,
          );
        }
        emit(
          state.copyWith(
            status: AnalyticsStatus.failure,
            period: state.dashboard?.period ?? period,
            errorMessage: _loadErrorMessage,
          ),
        );
      }
    }
  }
}
