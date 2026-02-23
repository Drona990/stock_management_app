import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entity/salse_entity.dart';
import '../../domain/repository/salse_repository.dart';

abstract class SaleEvent {}
class LoadSaleHistory extends SaleEvent {}
class PostSaleInvoice extends SaleEvent {
  final List<SaleItemEntry> items;
  PostSaleInvoice(this.items);
}

////////////////////////////////////////////////////////

abstract class SaleState {}
class SaleInitial extends SaleState {}
class SaleLoading extends SaleState {}
class SaleHistoryLoaded extends SaleState {
  final List<SaleHistoryEntity> history;
  SaleHistoryLoaded(this.history);
}

class SaleSuccess extends SaleState {
  final String msg;
  final SaleHistoryEntity newSale;

  SaleSuccess(this.msg, this.newSale);
}

class SaleError extends SaleState {
  final String msg;
  SaleError(this.msg);
}

///////////////////////////////////////////////////////////////

class SaleBloc extends Bloc<SaleEvent, SaleState> {
  final SaleRepository repo;

  SaleBloc(this.repo) : super(SaleInitial()) {
    on<LoadSaleHistory>((event, emit) async {
      debugPrint("📡 [SaleBloc] Loading History...");
      emit(SaleLoading());
      try {
        final data = await repo.getHistory();
        debugPrint("✅ [SaleBloc] History Loaded: ${data.length} records");
        emit(SaleHistoryLoaded(data));
      } catch (e) {
        debugPrint("❌ [SaleBloc] History Error: $e");
        emit(SaleError("Failed to load history: ${e.toString()}"));
      }
    });

    on<PostSaleInvoice>((event, emit) async {
      if (event.items.isEmpty) {
        debugPrint("⚠️ [SaleBloc] Empty cart attempt");
        emit(SaleError("Cart is empty!"));
        return;
      }

      emit(SaleLoading());
      debugPrint("🚀 [SaleBloc] Posting Invoice for ${event.items.length} items...");

      try {
        // 💡 Backend se naya data return karwa rahe hain
        final newSale = await repo.createSale(event.items);

        debugPrint("🏁 [SaleBloc] Transaction Success: ${newSale.invoiceNo}");

        // Success state mein message aur naya sale data dono bhej rahe hain
        emit(SaleSuccess("Invoice Created Successfully!", newSale));

        add(LoadSaleHistory()); // Auto refresh history
      } catch (e) {
        debugPrint("❌ [SaleBloc] Post Error: $e");
        emit(SaleError("Transaction Failed: $e"));
      }
    });
  }
}