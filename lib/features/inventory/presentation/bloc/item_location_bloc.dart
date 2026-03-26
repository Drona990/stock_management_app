import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart'; // Adjust path
import '../../../../injection.dart'; // Adjust path

// ==========================================================================
// 1. ENTITY & MODEL LAYER
// ==========================================================================

class ItemLocationEntity {
  final int? id;
  final String name;

  ItemLocationEntity({
    this.id,
    required this.name,
  });

  factory ItemLocationEntity.fromJson(Map<String, dynamic> json) =>
      ItemLocationEntity(
        id: json['id'],
        name: json['name'],
      );

  Map<String, dynamic> toJson() => {
    "name": name,
  };
}

// ==========================================================================
// 2. REPOSITORY LAYER
// ==========================================================================

class ItemLocationRepository {
  final ApiClient apiClient = sl<ApiClient>();

  Future<List<ItemLocationEntity>> getLocations({String? query}) async {
    final response = await apiClient.get(
      '/api/inventory/item-locations/',
      query: query != null ? {'search': query} : null,
    );

    print("itrm locations list: $response");

    // Handling Django Pagination 'results' key
    final List data = (response.data is Map && response.data.containsKey('results'))
        ? response.data['results']
        : response.data;

    return data.map((x) => ItemLocationEntity.fromJson(x)).toList();
  }

  Future<void> createLocation(ItemLocationEntity location) async {
    await apiClient.post('/api/inventory/item-locations/', data: location.toJson());
  }

  Future<void> updateLocation(int id, ItemLocationEntity location) async {
    await apiClient.put('/api/inventory/item-locations/$id/', data: location.toJson());
  }

  Future<void> deleteLocation(int id) async {
    await apiClient.delete('/api/inventory/item-locations/$id/');
  }
}

// ==========================================================================
// 3. BLOC EVENTS & STATES
// ==========================================================================

abstract class ItemLocationEvent {}

class LoadLocations extends ItemLocationEvent {
  final String? query;
  LoadLocations({this.query});
}

class AddLocation extends ItemLocationEvent {
  final ItemLocationEntity location;
  AddLocation(this.location);
}

class EditLocation extends ItemLocationEvent {
  final int id;
  final ItemLocationEntity location;
  EditLocation(this.id, this.location);
}

class DeleteLocation extends ItemLocationEvent {
  final int id;
  DeleteLocation(this.id);
}

abstract class ItemLocationState {}

class LocationInitial extends ItemLocationState {}

class LocationLoading extends ItemLocationState {}

class LocationLoaded extends ItemLocationState {
  final List<ItemLocationEntity> locations;
  LocationLoaded(this.locations);
}

class LocationError extends ItemLocationState {
  final String message;
  LocationError(this.message);
}

// ==========================================================================
// 4. BLOC LOGIC
// ==========================================================================

class ItemLocationBloc extends Bloc<ItemLocationEvent, ItemLocationState> {
  final ItemLocationRepository repository;

  ItemLocationBloc(this.repository) : super(LocationInitial()) {

    // FETCH & SEARCH
    on<LoadLocations>((event, emit) async {
      emit(LocationLoading());
      try {
        final data = await repository.getLocations(query: event.query);
        emit(LocationLoaded(data));
      } catch (e) {
        emit(LocationError(e.toString()));
      }
    });

    // ADD
    on<AddLocation>((event, emit) async {
      try {
        await repository.createLocation(event.location);
        add(LoadLocations());
      } catch (e) {
        emit(LocationError("Failed to add location"));
      }
    });

    // EDIT
    on<EditLocation>((event, emit) async {
      try {
        await repository.updateLocation(event.id, event.location);
        add(LoadLocations());
      } catch (e) {
        emit(LocationError("Failed to update location"));
      }
    });

    // DELETE
    on<DeleteLocation>((event, emit) async {
      try {
        await repository.deleteLocation(event.id);
        add(LoadLocations());
      } catch (e) {
        emit(LocationError("Failed to delete location"));
      }
    });
  }
}