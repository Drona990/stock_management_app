import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../injection.dart';

// ==========================================================================
// 1. ENTITY & MODEL LAYER
// ==========================================================================
class UserEntity {
  final String id;
  final String username;
  final String? email;
  final String role;

  UserEntity({
    required this.id,
    required this.username,
    this.email,
    required this.role,
  });

  factory UserEntity.fromJson(Map<String, dynamic> json) => UserEntity(
    id: (json['user_id'] ?? json['id'] ?? "").toString(),
    username: json['username'] ?? "",
    email: json['email'],
    role: json['role'] ?? "staff",
  );
}

class MenuOptionEntity {
  final String id;
  final String groupName;
  final String title;
  final String route;

  MenuOptionEntity({
    required this.id,
    required this.groupName,
    required this.title,
    required this.route,
  });

  factory MenuOptionEntity.fromJson(Map<String, dynamic> json) => MenuOptionEntity(
    id: (json['id'] ?? "").toString(),
    groupName: json['group_name'] ?? "",
    title: json['title'] ?? "",
    route: json['route'] ?? "",
  );
}

class UserPermissionMatrixEntity {
  final String userId;
  final List<String> allowedRoutes;

  UserPermissionMatrixEntity({
    required this.userId,
    required this.allowedRoutes,
  });

  factory UserPermissionMatrixEntity.fromJson(Map<String, dynamic> json) => UserPermissionMatrixEntity(
    userId: (json['user_id'] ?? "").toString(),
    allowedRoutes: List<String>.from(json['allowed_routes'] ?? []),
  );

  Map<String, dynamic> toJson() => {
    "user_id": userId,
    "allowed_routes": allowedRoutes,
  };
}

// ==========================================================================
// 2. REPOSITORY LAYER
// ==========================================================================
class UserPermissionsRepository {
  final ApiClient apiClient;

  UserPermissionsRepository({ApiClient? apiClient})
      : apiClient = apiClient ?? sl<ApiClient>();

  Future<List<UserEntity>> getUsers() async {
    final response = await apiClient.get('/api/users/directory/');

    final List data = (response.data is Map && response.data.containsKey('data'))
        ? response.data['data']
        : (response.data is Map && response.data.containsKey('results'))
        ? response.data['results']
        : response.data is List
        ? response.data
        : [];

    return data.map((x) => UserEntity.fromJson(x as Map<String, dynamic>)).toList();
  }

  Future<List<MenuOptionEntity>> getAllMenus() async {
    final response = await apiClient.get('/api/menus/all/');

    final List data = (response.data is Map && response.data.containsKey('data'))
        ? response.data['data']
        : response.data is List
        ? response.data
        : [];

    return data.map((x) => MenuOptionEntity.fromJson(x as Map<String, dynamic>)).toList();
  }

  Future<List<String>> getUserPermissions(String userId) async {
    final response = await apiClient.get('/api/user-permissions/$userId/');
    final List data = response.data['allowed_routes'] ?? [];
    return List<String>.from(data);
  }

  Future<void> updateUserPermissions(String userId, List<String> allowedRoutes) async {
    final payload = UserPermissionMatrixEntity(
      userId: userId,
      allowedRoutes: allowedRoutes,
    ).toJson();

    await apiClient.post('/api/user-permissions/update/', data: payload);
  }
}

// ==========================================================================
// 3. BLOC EVENTS, STATES & LOGIC LAYER
// ==========================================================================
abstract class UserPermissionsEvent {}

class LoadInitialData extends UserPermissionsEvent {}

class SelectUserEvent extends UserPermissionsEvent {
  final UserEntity user;
  SelectUserEvent(this.user);
}

class ToggleRoutePermission extends UserPermissionsEvent {
  final String route;
  final bool isAllowed;
  ToggleRoutePermission(this.route, this.isAllowed);
}

class ToggleGroupPermission extends UserPermissionsEvent {
  final List<String> routes;
  final bool enable;
  ToggleGroupPermission(this.routes, this.enable);
}

class SavePermissionsEvent extends UserPermissionsEvent {}

abstract class UserPermissionsState {}

class UserPermissionsInitial extends UserPermissionsState {}

class UserPermissionsLoading extends UserPermissionsState {}

class UserPermissionsLoaded extends UserPermissionsState {
  final List<UserEntity> users;
  final List<MenuOptionEntity> menus;
  final UserEntity selectedUser;
  final Set<String> allowedRoutes;
  final bool isSaving;

  UserPermissionsLoaded({
    required this.users,
    required this.menus,
    required this.selectedUser,
    required this.allowedRoutes,
    this.isSaving = false,
  });

  UserPermissionsLoaded copyWith({
    List<UserEntity>? users,
    List<MenuOptionEntity>? menus,
    UserEntity? selectedUser,
    Set<String>? allowedRoutes,
    bool? isSaving,
  }) {
    return UserPermissionsLoaded(
      users: users ?? this.users,
      menus: menus ?? this.menus,
      selectedUser: selectedUser ?? this.selectedUser,
      allowedRoutes: allowedRoutes ?? this.allowedRoutes,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class UserPermissionsError extends UserPermissionsState {
  final String message;
  UserPermissionsError(this.message);
}

class UserPermissionsSavedSuccess extends UserPermissionsState {
  final String username;
  UserPermissionsSavedSuccess(this.username);
}

class UserPermissionsBloc extends Bloc<UserPermissionsEvent, UserPermissionsState> {
  final UserPermissionsRepository repository;

  UserPermissionsBloc(this.repository) : super(UserPermissionsInitial()) {
    on<LoadInitialData>((event, emit) async {
      emit(UserPermissionsLoading());
      try {
        final users = await repository.getUsers();
        final menus = await repository.getAllMenus();

        if (users.isNotEmpty) {
          final firstUser = users.first;
          final routes = await repository.getUserPermissions(firstUser.id);
          emit(UserPermissionsLoaded(
            users: users,
            menus: menus,
            selectedUser: firstUser,
            allowedRoutes: routes.toSet(),
          ));
        } else {
          emit(UserPermissionsError("Zero user accounts mapped in database registries."));
        }
      } catch (e) {
        emit(UserPermissionsError("Sync Failure: ${e.toString()}"));
      }
    });

    on<SelectUserEvent>((event, emit) async {
      if (state is UserPermissionsLoaded) {
        final currentState = state as UserPermissionsLoaded;
        emit(currentState.copyWith(isSaving: true));
        try {
          final routes = await repository.getUserPermissions(event.user.id);
          emit(currentState.copyWith(
            selectedUser: event.user,
            allowedRoutes: routes.toSet(),
            isSaving: false,
          ));
        } catch (e) {
          emit(UserPermissionsError("Failed to fetch target user permissions."));
        }
      }
    });

    on<ToggleRoutePermission>((event, emit) {
      if (state is UserPermissionsLoaded) {
        final currentState = state as UserPermissionsLoaded;
        final updatedRoutes = Set<String>.from(currentState.allowedRoutes);

        if (event.isAllowed) {
          updatedRoutes.add(event.route);
        } else {
          updatedRoutes.remove(event.route);
        }

        emit(currentState.copyWith(allowedRoutes: updatedRoutes));
      }
    });

    on<ToggleGroupPermission>((event, emit) {
      if (state is UserPermissionsLoaded) {
        final currentState = state as UserPermissionsLoaded;
        final updatedRoutes = Set<String>.from(currentState.allowedRoutes);

        if (event.enable) {
          updatedRoutes.addAll(event.routes);
        } else {
          updatedRoutes.removeAll(event.routes);
        }

        emit(currentState.copyWith(allowedRoutes: updatedRoutes));
      }
    });

    on<SavePermissionsEvent>((event, emit) async {
      if (state is UserPermissionsLoaded) {
        final currentState = state as UserPermissionsLoaded;
        emit(currentState.copyWith(isSaving: true));

        try {
          await repository.updateUserPermissions(
            currentState.selectedUser.id,
            currentState.allowedRoutes.toList(),
          );
          emit(currentState.copyWith(isSaving: false));
          emit(UserPermissionsSavedSuccess(currentState.selectedUser.username));
          emit(currentState.copyWith(isSaving: false));
        } catch (e) {
          emit(UserPermissionsError("Failed to commit permission matrix."));
        }
      }
    });
  }
}

// ==========================================================================
// 4. MAIN VIEW SURFACE: HIGH-DENSITY ERP CANVAS (CUSTOM CARDS)
// ==========================================================================
class UserPermissionsScreen extends StatelessWidget {
  const UserPermissionsScreen({super.key});

  void _showSnackbar(BuildContext context, String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UserPermissionsBloc(UserPermissionsRepository())..add(LoadInitialData()),
      child: BlocListener<UserPermissionsBloc, UserPermissionsState>(
        listener: (context, state) {
          if (state is UserPermissionsSavedSuccess) {
            _showSnackbar(context, "Permissions committed for: ${state.username}", Colors.green);
          } else if (state is UserPermissionsError) {
            _showSnackbar(context, state.message, Colors.redAccent);
          }
        },
        child: Builder(
          builder: (newContext) {
            final bloc = newContext.read<UserPermissionsBloc>();

            return Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              body: Column(
                children: [
                  // ➡️ TOP ACTION BAR
                  _buildTopActionBar(bloc),

                  // ➡️ MAIN CANVAS
                  Expanded(
                    child: BlocBuilder<UserPermissionsBloc, UserPermissionsState>(
                      builder: (context, state) {
                        if (state is UserPermissionsLoading) {
                          return const Center(
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F172A)),
                          );
                        }

                        if (state is UserPermissionsLoaded) {
                          return SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Target User Header Card
                                _buildUserSelectorHeader(state, bloc),
                                const SizedBox(height: 16),

                                // Custom Group Cards Container
                                _buildPermissionsMatrixCards(state, bloc),
                              ],
                            ),
                          );
                        }

                        return const Center(
                          child: Text("Registry Load Error", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopActionBar(UserPermissionsBloc bloc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 4, height: 16, color: const Color(0xFF00BCD4)),
              const SizedBox(width: 8),
              const Text(
                "USER NAVIGATION ACCESS MATRIX",
                style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 13, letterSpacing: 0.5),
              ),
            ],
          ),
          BlocBuilder<UserPermissionsBloc, UserPermissionsState>(
            builder: (context, state) {
              bool isSaving = (state is UserPermissionsLoaded) && state.isSaving;

              return ElevatedButton.icon(
                onPressed: isSaving ? null : () => bloc.add(SavePermissionsEvent()),
                icon: isSaving
                    ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white))
                    : const Icon(Icons.security_rounded, size: 14),
                label: Text(
                  (isSaving ? "SAVING..." : "SAVE PERMISSIONS").toUpperCase(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserSelectorHeader(UserPermissionsLoaded state, UserPermissionsBloc bloc) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 600;

          return Flex(
            direction: isWide ? Axis.horizontal : Axis.vertical,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: isWide ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF00BCD4),
                    child: Text(
                      state.selectedUser.username.isNotEmpty ? state.selectedUser.username[0].toUpperCase() : "U",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "TARGET USER: ${state.selectedUser.username.toUpperCase()}",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.3),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "ROLE: ${state.selectedUser.role.toUpperCase()}  |  ALLOWED ROUTES: ${state.allowedRoutes.length}",
                        style: const TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
              if (!isWide) const SizedBox(height: 12),

              // Dropdown to Choose Target User
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    dropdownColor: Colors.white,
                    isDense: true,
                    value: state.selectedUser.id,
                    items: state.users.map((u) {
                      return DropdownMenuItem<String>(
                        value: u.id,
                        child: Text(
                          "${u.username.toUpperCase()} (${u.role.toUpperCase()})",
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                      );
                    }).toList(),
                    onChanged: (userId) {
                      if (userId != null) {
                        final user = state.users.firstWhere((element) => element.id == userId);
                        bloc.add(SelectUserEvent(user));
                      }
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPermissionsMatrixCards(UserPermissionsLoaded state, UserPermissionsBloc bloc) {
    final Map<String, List<MenuOptionEntity>> groupedMenus = {};
    for (var menu in state.menus) {
      groupedMenus.putIfAbsent(menu.groupName, () => []).add(menu);
    }

    return Column(
      children: groupedMenus.entries.map((entry) {
        final groupName = entry.key;
        final groupItems = entry.value;

        final groupRoutes = groupItems.map((e) => e.route).toList();
        final bool isAllGroupAllowed = groupRoutes.every((r) => state.allowedRoutes.contains(r));

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom Group Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.folder_outlined, size: 16, color: Color(0xFF00BCD4)),
                        const SizedBox(width: 8),
                        Text(
                          groupName.toUpperCase(),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF00BCD4), letterSpacing: 0.5),
                        ),
                      ],
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: () => bloc.add(ToggleGroupPermission(groupRoutes, !isAllGroupAllowed)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isAllGroupAllowed ? Colors.redAccent.withOpacity(0.1) : const Color(0xFF0F172A).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isAllGroupAllowed ? "DESELECT ALL" : "SELECT GROUP",
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isAllGroupAllowed ? Colors.redAccent : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Custom Container / Row Based Items List (NO ListTile)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: groupItems.map((menu) {
                    final bool isChecked = state.allowedRoutes.contains(menu.route);

                    return InkWell(
                      onTap: () => bloc.add(ToggleRoutePermission(menu.route, !isChecked)),
                      borderRadius: BorderRadius.circular(6),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isChecked ? const Color(0xFF00BCD4).withOpacity(0.04) : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isChecked ? const Color(0xFF00BCD4).withOpacity(0.3) : Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Custom Square Checkbox
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: Checkbox(
                                value: isChecked,
                                activeColor: const Color(0xFF00BCD4),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                onChanged: (bool? val) {
                                  if (val != null) {
                                    bloc.add(ToggleRoutePermission(menu.route, val));
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Custom Column Text Block
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    menu.title,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isChecked ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Route Path: ${menu.route}",
                                    style: const TextStyle(fontSize: 10, color: Colors.blueGrey, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),

                            // Custom Rounded Badge (ALLOWED / RESTRICTED)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isChecked ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isChecked ? "ENABLED" : "RESTRICTED",
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                  color: isChecked ? Colors.green : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}