import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart'; // Adjust path
import '../../../../injection.dart'; // Adjust path

// ==========================================================================
// 1. PRODUCT GROUP MASTER (Models, Repo, Bloc)
// ==========================================================================

class ProductGroupEntity {
  final int? id;
  final String name;
  final String? hsnCode;
  final double sgst;
  final double cgst;
  final double igst;

  ProductGroupEntity({
    this.id,
    required this.name,
    this.hsnCode,
    this.sgst = 0.0,
    this.cgst = 0.0,
    this.igst = 0.0,
  });

  factory ProductGroupEntity.fromJson(Map<String, dynamic> json) => ProductGroupEntity(
    id: json['id'],
    name: json['name'],
    hsnCode: json['hsn_code'],
    sgst: double.tryParse(json['sgst_rate'].toString()) ?? 0.0,
    cgst: double.tryParse(json['cgst_rate'].toString()) ?? 0.0,
    igst: double.tryParse(json['igst_rate'].toString()) ?? 0.0,
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "hsn_code": hsnCode,
    "sgst_rate": sgst,
    "cgst_rate": cgst,
    "igst_rate": igst,
  };
}

class ProductGroupRepository {
  final ApiClient apiClient = sl<ApiClient>();

  Future<List<ProductGroupEntity>> getGroups({String? query}) async {
    final response = await apiClient.get(
      '/api/inventory/product-groups/',
      query: query != null ? {'search': query} : null,
    );
    final List data = (response.data is Map && response.data.containsKey('results'))
        ? response.data['results']
        : response.data;
    return data.map((x) => ProductGroupEntity.fromJson(x)).toList();
  }

  Future<void> createGroup(ProductGroupEntity group) async =>
      await apiClient.post('/api/inventory/product-groups/', data: group.toJson());

  Future<void> updateGroup(int id, ProductGroupEntity group) async =>
      await apiClient.put('/api/inventory/product-groups/$id/', data: group.toJson());

  Future<void> deleteGroup(int id) async =>
      await apiClient.delete('/api/inventory/product-groups/$id/');
}

abstract class ProductGroupEvent {}
class LoadGroups extends ProductGroupEvent { final String? query; LoadGroups({this.query}); }
class AddGroup extends ProductGroupEvent { final ProductGroupEntity group; AddGroup(this.group); }
class EditGroup extends ProductGroupEvent { final int id; final ProductGroupEntity group; EditGroup(this.id, this.group); }
class DeleteGroup extends ProductGroupEvent { final int id; DeleteGroup(this.id); }

abstract class ProductGroupState {}
class GroupInitial extends ProductGroupState {}
class GroupLoading extends ProductGroupState {}
class GroupLoaded extends ProductGroupState { final List<ProductGroupEntity> groups; GroupLoaded(this.groups); }
class GroupError extends ProductGroupState { final String message; GroupError(this.message); }

class ProductGroupBloc extends Bloc<ProductGroupEvent, ProductGroupState> {
  final ProductGroupRepository repository;
  ProductGroupBloc(this.repository) : super(GroupInitial()) {
    on<LoadGroups>((event, emit) async {
      emit(GroupLoading());
      try {
        final data = await repository.getGroups(query: event.query);
        emit(GroupLoaded(data));
      } catch (e) { emit(GroupError(e.toString())); }
    });
    on<AddGroup>((event, emit) async {
      try { await repository.createGroup(event.group); add(LoadGroups()); }
      catch (e) { emit(GroupError("Failed to add group")); }
    });
    on<EditGroup>((event, emit) async {
      try { await repository.updateGroup(event.id, event.group); add(LoadGroups()); }
      catch (e) { emit(GroupError("Failed to update group")); }
    });
    on<DeleteGroup>((event, emit) async {
      try { await repository.deleteGroup(event.id); add(LoadGroups()); }
      catch (e) { emit(GroupError("Failed to delete group")); }
    });
  }
}

// ==========================================================================
// 2. PRODUCT SUB MASTER (Models, Repo, Bloc)
// ==========================================================================

class ProductSubGroupEntity {
  final int? id;
  final int groupId;
  final String? groupName;
  final String name;

  ProductSubGroupEntity({
    this.id,
    required this.groupId,
    this.groupName,
    required this.name,
  });

  factory ProductSubGroupEntity.fromJson(Map<String, dynamic> json) => ProductSubGroupEntity(
    id: json['id'],
    groupId: json['group'],
    groupName: json['group_name'],
    name: json['name'],
  );

  Map<String, dynamic> toJson() => {
    "group": groupId,
    "name": name,
  };
}

class ProductSubGroupRepository {
  final ApiClient apiClient = sl<ApiClient>();

  Future<List<ProductSubGroupEntity>> getSubGroups({int? groupId, String? query}) async {
    Map<String, dynamic> params = {};
    if (groupId != null) params['group'] = groupId;
    if (query != null) params['search'] = query;

    final response = await apiClient.get('/api/inventory/product-subgroups/', query: params);
    final List data = (response.data is Map && response.data.containsKey('results'))
        ? response.data['results']
        : response.data;
    return data.map((x) => ProductSubGroupEntity.fromJson(x)).toList();
  }

  Future<void> createSubGroup(ProductSubGroupEntity subGroup) async =>
      await apiClient.post('/api/inventory/product-subgroups/', data: subGroup.toJson());

  Future<void> updateSubGroup(int id, ProductSubGroupEntity subGroup) async =>
      await apiClient.put('/api/inventory/product-subgroups/$id/', data: subGroup.toJson());

  Future<void> deleteSubGroup(int id) async =>
      await apiClient.delete('/api/inventory/product-subgroups/$id/');
}

abstract class SubGroupEvent {}
class LoadSubGroups extends SubGroupEvent { final int? groupId; final String? query; LoadSubGroups({this.groupId, this.query}); }
class AddSubGroup extends SubGroupEvent { final ProductSubGroupEntity subGroup; AddSubGroup(this.subGroup); }
class EditSubGroup extends SubGroupEvent { final int id; final ProductSubGroupEntity subGroup; EditSubGroup(this.id, this.subGroup); }
class DeleteSubGroup extends SubGroupEvent { final int id; DeleteSubGroup(this.id); }

abstract class SubGroupState {}
class SubGroupInitial extends SubGroupState {}
class SubGroupLoading extends SubGroupState {}
class SubGroupLoaded extends SubGroupState { final List<ProductSubGroupEntity> subGroups; SubGroupLoaded(this.subGroups); }
class SubGroupError extends SubGroupState { final String message; SubGroupError(this.message); }

class ProductSubGroupBloc extends Bloc<SubGroupEvent, SubGroupState> {
  final ProductSubGroupRepository repository;
  ProductSubGroupBloc(this.repository) : super(SubGroupInitial()) {
    on<LoadSubGroups>((event, emit) async {
      emit(SubGroupLoading());
      try {
        final data = await repository.getSubGroups(groupId: event.groupId, query: event.query);
        emit(SubGroupLoaded(data));
      } catch (e) { emit(SubGroupError(e.toString())); }
    });
    on<AddSubGroup>((event, emit) async {
      try { await repository.createSubGroup(event.subGroup); add(LoadSubGroups()); }
      catch (e) { emit(SubGroupError("Failed to add sub-group")); }
    });
    on<EditSubGroup>((event, emit) async {
      try { await repository.updateSubGroup(event.id, event.subGroup); add(LoadSubGroups()); }
      catch (e) { emit(SubGroupError("Failed to update sub-group")); }
    });
    on<DeleteSubGroup>((event, emit) async {
      try { await repository.deleteSubGroup(event.id); add(LoadSubGroups()); }
      catch (e) { emit(SubGroupError("Failed to delete sub-group")); }
    });
  }
}