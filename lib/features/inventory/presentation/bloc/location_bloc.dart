import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart'; // Adjust path
import '../../../../injection.dart'; // Adjust path

// ==========================================================================
// 1. ENTITY & MODEL LAYER
// ==========================================================================

class LocationEntity {
  final int? id;
  final String name;

  LocationEntity({
    this.id,
    required this.name,
  });

  factory LocationEntity.fromJson(Map<String, dynamic> json) =>
      LocationEntity(
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

class LocationRepository {
  final ApiClient apiClient = sl<ApiClient>();

  Future<List<LocationEntity>> getLocations({String? query}) async {
    final response = await apiClient.get(
      '/api/inventory/locations/',
      query: query != null ? {'search': query} : null,
    );

    // Handling Django Pagination 'results' key
    final List data = (response.data is Map && response.data.containsKey('results'))
        ? response.data['results']
        : response.data;

    return data.map((x) => LocationEntity.fromJson(x)).toList();
  }

  Future<void> createLocation(LocationEntity location) async {
    await apiClient.post('/api/inventory/locations/', data: location.toJson());
  }

  Future<void> updateLocation(int id, LocationEntity location) async {
    await apiClient.put('/api/inventory/locations/$id/', data: location.toJson());
  }

  Future<void> deleteLocation(int id) async {
    await apiClient.delete('/api/inventory/locations/$id/');
  }
}

// ==========================================================================
// 3. BLOC EVENTS & STATES
// ==========================================================================

abstract class LocationEvent {}

class LoadLocations extends LocationEvent {
  final String? query;
  LoadLocations({this.query});
}

class AddLocation extends LocationEvent {
  final LocationEntity location;
  AddLocation(this.location);
}

class EditLocation extends LocationEvent {
  final int id;
  final LocationEntity location;
  EditLocation(this.id, this.location);
}

class DeleteLocation extends LocationEvent {
  final int id;
  DeleteLocation(this.id);
}

abstract class LocationState {}

class LocationInitial extends LocationState {}

class LocationLoading extends LocationState {}

class LocationLoaded extends LocationState {
  final List<LocationEntity> locations;
  LocationLoaded(this.locations);
}

class LocationError extends LocationState {
  final String message;
  LocationError(this.message);
}

// ==========================================================================
// 4. BLOC LOGIC
// ==========================================================================

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final LocationRepository repository;

  LocationBloc(this.repository) : super(LocationInitial()) {

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