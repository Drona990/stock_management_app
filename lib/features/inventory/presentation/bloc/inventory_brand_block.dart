import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';

// ==========================================================================
// 1. ENTITY & MODEL LAYER
// ==========================================================================

class InventoryBrandEntity {
  final int? id;
  final String name;
  final String? origin;

  InventoryBrandEntity({
    this.id,
    required this.name,
    this.origin,
  });

  factory InventoryBrandEntity.fromJson(Map<String, dynamic> json) =>
      InventoryBrandEntity(
        id: json['id'],
        name: json['name'],
        origin: json['origin'],
      );

  Map<String, dynamic> toJson() => {
    "name": name,
    "origin": origin,
  };
}

// ==========================================================================
// 2. REPOSITORY LAYER
// ==========================================================================

class InventoryBrandRepository {
  final ApiClient apiClient = sl<ApiClient>();

  Future<List<InventoryBrandEntity>> getBrands({String? query}) async {
    final response = await apiClient.get(
      '/api/inventory/brands/',
      query: query != null ? {'search': query} : null,
    );

    final List data = (response.data is Map && response.data.containsKey('results'))
        ? response.data['results']
        : response.data;

    return data.map((x) => InventoryBrandEntity.fromJson(x)).toList();
  }

  Future<void> createBrand(InventoryBrandEntity brand) async {
    await apiClient.post('/api/inventory/brands/', data: brand.toJson());
  }

  Future<void> updateBrand(int id, InventoryBrandEntity brand) async {
    await apiClient.put('/api/inventory/brands/$id/', data: brand.toJson());
  }

  Future<void> deleteBrand(int id) async {
    await apiClient.delete('/api/inventory/brands/$id/');
  }
}

// ==========================================================================
// 3. BLOC EVENTS & STATES
// ==========================================================================

abstract class InventoryBrandEvent {}

class LoadInvBrands extends InventoryBrandEvent {
  final String? query;
  LoadInvBrands({this.query});
}

class AddInvBrand extends InventoryBrandEvent {
  final InventoryBrandEntity brand;
  AddInvBrand(this.brand);
}

class EditInvBrand extends InventoryBrandEvent {
  final int id;
  final InventoryBrandEntity brand;
  EditInvBrand(this.id, this.brand);
}

class DeleteInvBrand extends InventoryBrandEvent {
  final int id;
  DeleteInvBrand(this.id);
}

abstract class InventoryBrandState {}

class InvBrandInitial extends InventoryBrandState {}
class InvBrandLoading extends InventoryBrandState {}
class InvBrandLoaded extends InventoryBrandState {
  final List<InventoryBrandEntity> brands;
  InvBrandLoaded(this.brands);
}
class InvBrandError extends InventoryBrandState {
  final String message;
  InvBrandError(this.message);
}

// ==========================================================================
// 4. BLOC LOGIC
// ==========================================================================

class InventoryBrandBloc extends Bloc<InventoryBrandEvent, InventoryBrandState> {
  final InventoryBrandRepository repository;

  InventoryBrandBloc(this.repository) : super(InvBrandInitial()) {

    on<LoadInvBrands>((event, emit) async {
      emit(InvBrandLoading());
      try {
        final data = await repository.getBrands(query: event.query);
        emit(InvBrandLoaded(data));
      } catch (e) {
        emit(InvBrandError(e.toString()));
      }
    });

    on<AddInvBrand>((event, emit) async {
      try {
        await repository.createBrand(event.brand);
        add(LoadInvBrands());
      } catch (e) {
        emit(InvBrandError("Failed to add brand"));
      }
    });

    on<EditInvBrand>((event, emit) async {
      try {
        await repository.updateBrand(event.id, event.brand);
        add(LoadInvBrands());
      } catch (e) {
        emit(InvBrandError("Failed to update brand"));
      }
    });

    on<DeleteInvBrand>((event, emit) async {
      try {
        await repository.deleteBrand(event.id);
        add(LoadInvBrands());
      } catch (e) {
        emit(InvBrandError("Failed to delete brand"));
      }
    });
  }
}