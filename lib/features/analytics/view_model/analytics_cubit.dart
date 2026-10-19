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

  /// Loads the dashboard for the selected period.
  Future<void> load() => _load(state.period);

  /// Selects [period] and reloads the dashboard when it changed.
  Future<void> selectPeriod(AnalyticsPeriod period) async {
    if (period == state.period) {
      return;
    }
    await _load(period);
  }

  Future<void> _load(AnalyticsPeriod period) async {
    if (_isLoading || isClosed) {
      return;
    }
    _isLoading = true;
    emit(AnalyticsState(period: period));
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
    } on Exception {
      if (!isClosed) {
        emit(
          AnalyticsState(
            status: AnalyticsStatus.failure,
            period: period,
            errorMessage: _loadErrorMessage,
          ),
        );
      }
    } finally {
      _isLoading = false;
    }
  }
}
