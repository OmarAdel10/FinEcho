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
  int _generation =
      0; // Practically never overflows (9e18 clears); no wrap handling.

  /// Loads the dashboard for the selected period.
  ///
  /// A load requested while another one is running waits for it to settle and
  /// then reloads, so callers like pull-to-refresh observe fresh data. A
  /// request that settles behind a cleared generation stops without
  /// reloading.
  Future<void> load() async {
    final generation = _generation;
    while (!isClosed) {
      final inFlight = _inFlight;
      if (inFlight != null) {
        await inFlight;
        if (_generation != generation) {
          return;
        }
        continue;
      }
      await _load(state.period);
      return;
    }
  }

  /// Selects [period] and reloads the dashboard when it changed.
  ///
  /// A selection made while a load is in flight is queued and applied as soon
  /// as the running load settles. A cache clear during the load drops the
  /// queued selection instead of rerunning it behind the lock.
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

  /// Clears the cached dashboard and pending period selection.
  ///
  /// Called when the app lock engages, so any decrypted aggregates are
  /// dropped from memory behind the lock screen. Loads that started before
  /// the clear stop when they settle instead of repopulating the dashboard.
  ///
  /// The cubit holds the only derived-aggregate cache; AnalyticsService
  /// recomputes from the repositories on every call.
  void clearCachedDashboard() {
    if (isClosed) {
      return;
    }
    _generation++;
    _pendingPeriod = null;
    emit(const AnalyticsState());
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
    final generation = _generation;
    _isLoading = true;
    try {
      var targetPeriod = period;
      while (!isClosed && _generation == generation) {
        emit(
          state.copyWith(
            status: AnalyticsStatus.loading,
            period: targetPeriod,
            clearErrorMessage: true,
          ),
        );
        await _attemptLoad(targetPeriod);
        if (!isClosed && _generation != generation) {
          break;
        }
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
    final generation = _generation;
    try {
      final dashboard = await _service.loadDashboard(period: period);
      if (!isClosed && generation == _generation) {
        emit(
          AnalyticsState(
            status: AnalyticsStatus.ready,
            period: period,
            dashboard: dashboard,
          ),
        );
      }
    } on Object catch (error, stackTrace) {
      if (!isClosed && generation == _generation) {
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
