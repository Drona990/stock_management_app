import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';

// =============================================================================
// REPOSITORY
// =============================================================================
class LedgerRepository {
  final ApiClient apiClient = sl<ApiClient>();

  Future<Map<String, dynamic>> fetchLedger({
    String? name,
    String? fromDate,
    String? toDate,
    String? type,
    String? search,
  }) async {
    final response = await apiClient.get(
      '/api/transactions/ledger-report/',
      query: { // Fixed: Using queryParameters for Dio/ApiClient
        if (name != null && name.isNotEmpty) 'name': name,
        if (fromDate != null) 'from_date': fromDate,
        if (toDate != null) 'to_date': toDate,
        if (type != null && type != "All") 'type': type.toUpperCase(),
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return response.data;
  }
}

// =============================================================================
// BLOC
// =============================================================================
abstract class LedgerEvent {}
class LoadLedgerData extends LedgerEvent {
  final String? name, fromDate, toDate, type, search;
  LoadLedgerData({this.name, this.fromDate, this.toDate, this.type, this.search});
}

abstract class LedgerState {}
class LedgerLoading extends LedgerState {}
class LedgerLoaded extends LedgerState {
  final List data;
  final Map summary;
  LedgerLoaded(this.data, this.summary);
}
class LedgerError extends LedgerState { final String message; LedgerError(this.message); }

class LedgerBloc extends Bloc<LedgerEvent, LedgerState> {
  final LedgerRepository repo;
  // Memory to keep filters alive across search/date changes
  final Map<String, String?> _currentFilters = {"type": "All"};

  LedgerBloc(this.repo) : super(LedgerLoading()) {
    on<LoadLedgerData>((event, emit) async {
      emit(LedgerLoading());

      if (event.type != null) _currentFilters['type'] = event.type;
      if (event.search != null) _currentFilters['search'] = event.search;
      if (event.fromDate != null) _currentFilters['from_date'] = event.fromDate;
      if (event.toDate != null) _currentFilters['to_date'] = event.toDate;
      if (event.name != null) _currentFilters['name'] = event.name;

      try {
        final res = await repo.fetchLedger(
          name: _currentFilters['name'],
          fromDate: _currentFilters['from_date'],
          toDate: _currentFilters['to_date'],
          type: _currentFilters['type'],
          search: _currentFilters['search'],
        );
        emit(LedgerLoaded(res['data'] ?? [], res['summary'] ?? {}));
      } catch (e) {
        emit(LedgerError("Ledger Load Failed: ${e.toString()}"));
      }
    });
  }
}