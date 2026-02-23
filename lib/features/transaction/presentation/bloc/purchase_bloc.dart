import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entity/purchase_entity.dart';
import '../../domain/repository/purchase_repository.dart';

abstract class PurchaseEvent {}
class LoadPurchaseHistory extends PurchaseEvent {}
class PostPurchaseBill extends PurchaseEvent {
  final int supplierId;
  final String billNo;
  final String mode;
  final List<PurchaseItemEntry> items;
  PostPurchaseBill(this.supplierId, this.billNo, this.mode, this.items);
}

abstract class PurchaseState {}
class PurchaseInitial extends PurchaseState {}
class PurchaseLoading extends PurchaseState {}
class PurchaseLoaded extends PurchaseState { final List<PurchaseHistoryEntity> history; PurchaseLoaded(this.history); }
class PurchaseSuccess extends PurchaseState { final String msg; PurchaseSuccess(this.msg); }
class PurchaseError extends PurchaseState { final String msg; PurchaseError(this.msg); }

class PurchaseBloc extends Bloc<PurchaseEvent, PurchaseState> {
  final PurchaseRepository repo;
  PurchaseBloc(this.repo) : super(PurchaseInitial()) {
    on<LoadPurchaseHistory>((event, emit) async {
      emit(PurchaseLoading());
      try {
        final data = await repo.getHistory();
        emit(PurchaseLoaded(data));
      } catch (e) { emit(PurchaseError(e.toString())); }
    });

    on<PostPurchaseBill>((event, emit) async {
      emit(PurchaseLoading());
      try {
        await repo.createPurchase({
          "supplier": event.supplierId,
          "bill_number": event.billNo,
          "purchase_date": DateTime.now().toIso8601String(),
          "payment_mode": event.mode,
          "items_data": event.items.map((e) => e.toJson()).toList(),
        });
        emit(PurchaseSuccess("Stock Inward Successful!"));
        add(LoadPurchaseHistory());
      } catch (e) { emit(PurchaseError("Failed to save: ${e.toString()}")); }
    });
  }
}