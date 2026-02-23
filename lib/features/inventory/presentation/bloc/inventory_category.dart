import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart'; // Adjust path
import '../../../../injection.dart'; // Adjust path

// ==========================================================================
// 1. ENTITY & MODEL LAYER
// ==========================================================================

class InventoryCategoryEntity {
  final int? id;
  final String name;
  final String? description;

  InventoryCategoryEntity({
    this.id,
    required this.name,
    this.description,
  });

  factory InventoryCategoryEntity.fromJson(Map<String, dynamic> json) =>
      InventoryCategoryEntity(
        id: json['id'],
        name: json['name'],
        description: json['description'],
      );

  Map<String, dynamic> toJson() => {
    "name": name,
    "description": description,
  };
}

// ==========================================================================
// 2. REPOSITORY LAYER
// ==========================================================================

class InventoryCategoryRepository {
  final ApiClient apiClient = sl<ApiClient>();

  Future<List<InventoryCategoryEntity>> getCategories({String? query}) async {
    final response = await apiClient.get(
      '/api/inventory/categories/',
      query: query != null ? {'search': query} : null,
    );

    // Handling Django Pagination 'results' key
    final List data = (response.data is Map && response.data.containsKey('results'))
        ? response.data['results']
        : response.data;

    return data.map((x) => InventoryCategoryEntity.fromJson(x)).toList();
  }

  Future<void> createCategory(InventoryCategoryEntity category) async {
    await apiClient.post('/api/inventory/categories/', data: category.toJson());
  }

  Future<void> updateCategory(int id, InventoryCategoryEntity category) async {
    await apiClient.put('/api/inventory/categories/$id/', data: category.toJson());
  }

  Future<void> deleteCategory(int id) async {
    await apiClient.delete('/api/inventory/categories/$id/');
  }
}

// ==========================================================================
// 3. BLOC EVENTS & STATES
// ==========================================================================

abstract class InventoryCategoryEvent {}

class LoadInvCategories extends InventoryCategoryEvent {
  final String? query;
  LoadInvCategories({this.query});
}

class AddInvCategory extends InventoryCategoryEvent {
  final InventoryCategoryEntity category;
  AddInvCategory(this.category);
}

class EditInvCategory extends InventoryCategoryEvent {
  final int id;
  final InventoryCategoryEntity category;
  EditInvCategory(this.id, this.category);
}

class DeleteInvCategory extends InventoryCategoryEvent {
  final int id;
  DeleteInvCategory(this.id);
}

abstract class InventoryCategoryState {}

class InvCategoryInitial extends InventoryCategoryState {}
class InvCategoryLoading extends InventoryCategoryState {}
class InvCategoryLoaded extends InventoryCategoryState {
  final List<InventoryCategoryEntity> categories;
  InvCategoryLoaded(this.categories);
}
class InvCategoryError extends InventoryCategoryState {
  final String message;
  InvCategoryError(this.message);
}

// ==========================================================================
// 4. BLOC LOGIC
// ==========================================================================

class InventoryCategoryBloc extends Bloc<InventoryCategoryEvent, InventoryCategoryState> {
  final InventoryCategoryRepository repository;

  InventoryCategoryBloc(this.repository) : super(InvCategoryInitial()) {

    // FETCH & SEARCH
    on<LoadInvCategories>((event, emit) async {
      emit(InvCategoryLoading());
      try {
        final data = await repository.getCategories(query: event.query);
        emit(InvCategoryLoaded(data));
      } catch (e) {
        emit(InvCategoryError(e.toString()));
      }
    });

    // ADD
    on<AddInvCategory>((event, emit) async {
      try {
        await repository.createCategory(event.category);
        add(LoadInvCategories());
      } catch (e) {
        emit(InvCategoryError("Failed to add category"));
      }
    });

    // EDIT
    on<EditInvCategory>((event, emit) async {
      try {
        await repository.updateCategory(event.id, event.category);
        add(LoadInvCategories());
      } catch (e) {
        emit(InvCategoryError("Failed to update category"));
      }
    });

    // DELETE
    on<DeleteInvCategory>((event, emit) async {
      try {
        await repository.deleteCategory(event.id);
        add(LoadInvCategories());
      } catch (e) {
        emit(InvCategoryError("Failed to delete category"));
      }
    });
  }
}