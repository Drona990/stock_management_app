// Events
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entity/stock_log_entity.dart';
import '../../domain/repository/stock_repository.dart';

abstract class StockEvent {}
class FetchStockLogs extends StockEvent { final String? productId; final String? type; FetchStockLogs({this.productId, this.type}); }
class CreateWastageEntry extends StockEvent { final WastageEntity wastage; CreateWastageEntry(this.wastage); }

// States
abstract class StockState {}
class StockInitial extends StockState {}
class StockLoading extends StockState {}
class StockLogsLoaded extends StockState { final List<StockLogEntity> logs; StockLogsLoaded(this.logs); }
class WastageSuccess extends StockState {}
class StockError extends StockState { final String msg; StockError(this.msg); }

class StockBloc extends Bloc<StockEvent, StockState> {
  final StockRepository repo;
  StockBloc(this.repo) : super(StockInitial()) {
    on<FetchStockLogs>((event, emit) async {
      emit(StockLoading());
      try {
        final logs = await repo.getStockLogs(productId: event.productId, type: event.type);
        emit(StockLogsLoaded(logs));
      } catch (e) { emit(StockError(e.toString())); }
    });

    on<CreateWastageEntry>((event, emit) async {
      emit(StockLoading());
      try {
        await repo.reportWastage(event.wastage);
        emit(WastageSuccess());
        add(FetchStockLogs()); // Refresh logs after wastage
      } catch (e) { emit(StockError(e.toString())); }
    });
  }
}