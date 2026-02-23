

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entity/dashboard_stock_summary_entity.dart';
import '../../domain/repository/dashboard_stock_summary_reposotory.dart';

// --- Events ---
abstract class DashboardEvent {}
class FetchDashboardStats extends DashboardEvent {}

// --- States ---
abstract class DashboardState {}
class DashboardInitial extends DashboardState {}
class DashboardLoading extends DashboardState {}
class DashboardLoaded extends DashboardState {
  final DashboardStockSummaryEntity summary;
  DashboardLoaded(this.summary);
}
class DashboardError extends DashboardState {
  final String message;
  DashboardError(this.message);
}

// --- Bloc Logic ---
class DashboardStockBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardStockSummaryRepository repo;

  DashboardStockBloc(this.repo) : super(DashboardInitial()) {
    on<FetchDashboardStats>((event, emit) async {
      debugPrint("🚀 [BLOC LOG] FetchDashboardStats Event Triggered");
      emit(DashboardLoading());

      try {
        final data = await repo.getSummary();

        debugPrint("🏁 [BLOC LOG] Data Loaded into Bloc. Emitting DashboardLoaded.");

        emit(DashboardLoaded(data));
      } catch (e) {
        debugPrint("⚠️ [BLOC LOG] Error in Bloc: $e");
        emit(DashboardError("Stats load nahi ho paye: $e"));
      }
    });
  }
}