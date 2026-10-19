import 'package:bloc/bloc.dart';
import 'package:finecho/features/analytics/view_model/models/analytics_period.dart';
import 'package:finecho/features/analytics/view_model/models/analytics_state.dart';
import 'package:finecho/features/analytics/view_model/services/analytics_service.dart';

const String _loadErrorMessage =
    'Could not load your statistics. Please try again.';

/// Coordinates statistics dashboard state for the analytics screen.
class AnalyticsCubit extends Cubit<AnalyticsState> {
  /// Creates an analytics cubit backed by the analytics service.
  new(this._service) : super(const AnalyticsState());

  final AnalyticsService _service;
  bool _isLoading = false;
  AnalyticsPeriod? _pendingPeriod;

  /// Loads the dashboard for the selected period.
  Future<void> load() => _load(state.period);

  /// Selects [period] and reloads the dashboard when it changed.
  ///
  /// A selection made while a load is in flight is queued and applied as soon
  /// as the running load settles.
  Future<void> selectPeriod(AnalyticsPeriod period) async {
    if (period == state.period && _pendingPeriod == null) {
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

  Future<void> _load(AnalyticsPeriod period) async {
    if (_isLoading || isClosed) {
      return;
    }
    _isLoading = true;
    emit(
      state.copyWith(
        status: AnalyticsStatus.loading,
        period: period,
        clearErrorMessage: true,
      ),
    );
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
    } on Object {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: AnalyticsStatus.failure,
            period: period,
            errorMessage: _loadErrorMessage,
          ),
        );
      }
    } finally {
      _isLoading = false;
      final pendingPeriod = _pendingPeriod;
      if (pendingPeriod != null && !isClosed) {
        _pendingPeriod = null;
        await _load(pendingPeriod);
      }
    }
  }
}
