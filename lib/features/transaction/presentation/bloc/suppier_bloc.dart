import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entity/supplier_entity.dart';
import '../../domain/repository/supplier_repository.dart';

abstract class SupplierEvent {}
class LoadSuppliers extends SupplierEvent {}
class AddSupplier extends SupplierEvent { final SupplierEntity supplier; AddSupplier(this.supplier); }
class DeleteSupplier extends SupplierEvent { final int id; DeleteSupplier(this.id); }

abstract class SupplierState {}
class SupplierLoading extends SupplierState {}
class SupplierLoaded extends SupplierState { final List<SupplierEntity> suppliers; SupplierLoaded(this.suppliers); }
class SupplierError extends SupplierState { final String msg; SupplierError(this.msg); }

class SupplierBloc extends Bloc<SupplierEvent, SupplierState> {
  final SupplierRepository repo;
  SupplierBloc(this.repo) : super(SupplierLoading()) {
    on<LoadSuppliers>((event, emit) async {
      emit(SupplierLoading());
      try { emit(SupplierLoaded(await repo.getSuppliers())); }
      catch (e) { emit(SupplierError(e.toString())); }
    });

    on<AddSupplier>((event, emit) async {
      try {
        await repo.createSupplier(event.supplier);
        add(LoadSuppliers());
      } catch (e) { emit(SupplierError("Failed to add vendor")); }
    });

    on<DeleteSupplier>((event, emit) async {
      try {
        await repo.deleteSupplier(event.id);
        add(LoadSuppliers());
      } catch (e) { emit(SupplierError("Cannot delete vendor with purchase history")); }
    });
  }
}