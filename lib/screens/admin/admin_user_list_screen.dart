// lib/screens/admin/admin_user_list_screen.dart

// ignore_for_file: no_leading_underscores_for_local_identifiers, use_build_context_synchronously, unnecessary_null_comparison, dead_code

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartsales365/models/role_model.dart';
import 'package:smartsales365/models/user_model.dart';
import 'package:smartsales365/providers/auth_provider.dart';
import 'package:smartsales365/services/user_service.dart';

class AdminUserListScreen extends StatefulWidget {
  const AdminUserListScreen({super.key});

  @override
  State<AdminUserListScreen> createState() => _AdminUserListScreenState();
}

class _AdminUserListScreenState extends State<AdminUserListScreen> {
  final UserService _userService = UserService();
  late Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  /// Carga usuarios y roles al mismo tiempo
  void _fetchData() {
    setState(() {
      _dataFuture = _loadData();
    });
  }

  Future<Map<String, dynamic>> _loadData() async {
    // CORRECCIÓN 1/3:
    // Cambiado de 'accessToken' a 'token'
    final String? token = context.read<AuthProvider>().token;
    if (token == null) {
      throw Exception('No autorizado');
    }
    final users = await _userService.getUsers(token);
    final roles = await _userService.getRoles(token);
    return {'users': users, 'roles': roles};
  }

  /// Muestra el diálogo para editar el rol de un usuario
  Future<void> _showEditRoleDialog(
    User user,
    List<Role> allRoles,
    String token,
  ) async {
    // El ID del rol actual del usuario (puede ser nulo si es un 'Cliente' sin rol asignado)
    int? selectedRoleId = user.role.id;

    // Asegurarnos de que el rol "Cliente" (ID 1) sea una opción válida
    // si el usuario no tiene rol o si su rol no está en la lista (poco probable)
    if (selectedRoleId == null &&
        allRoles.any((role) => role.name == 'Cliente')) {
      selectedRoleId = allRoles.firstWhere((r) => r.name == 'Cliente').id;
    }

    final newRoleId = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Editar Rol de ${user.username}'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return DropdownButton<int>(
                value: selectedRoleId,
                isExpanded: true,
                hint: const Text('Seleccionar rol'),
                items: allRoles.map((Role role) {
                  return DropdownMenuItem<int>(
                    value: role.id,
                    child: Text(role.name),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  setState(() {
                    selectedRoleId = newValue;
                  });
                },
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Guardar'),
              onPressed: () {
                Navigator.of(context).pop(selectedRoleId);
              },
            ),
          ],
        );
      },
    );

    if (newRoleId != null && newRoleId != user.role?.id) {
      try {
        await _userService.updateUserRole(
          token,
          user.id,
          {'role_id': newRoleId} as int,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rol de usuario actualizado'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchData(); // Refresca la lista de usuarios
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar el rol: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Muestra el diálogo para editar los detalles de un usuario
  Future<void> _showEditUserDialog(User user, String token) async {
    final _formKey = GlobalKey<FormState>();
    final _usernameController = TextEditingController(text: user.username);
    final _emailController = TextEditingController(text: user.email);
    final _firstNameController = TextEditingController(text: user.firstName);
    final _lastNameController = TextEditingController(text: user.lastName);
    final _passwordController =
        TextEditingController(); // Para nueva contraseña

    final Map<String, String>? result = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Editar Usuario ${user.username}'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'Username'),
                    validator: (val) => val!.isEmpty ? 'Requerido' : null,
                  ),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) => val!.isEmpty ? 'Requerido' : null,
                  ),
                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                  ),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(labelText: 'Apellido'),
                  ),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Nueva Contraseña',
                      hintText: 'Dejar vacío para no cambiar',
                    ),
                    obscureText: true,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Guardar'),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  Navigator.of(context).pop({
                    'username': _usernameController.text,
                    'email': _emailController.text,
                    'first_name': _firstNameController.text,
                    'last_name': _lastNameController.text,
                    'password': _passwordController.text,
                  });
                }
              },
            ),
          ],
        );
      },
    );

    if (result != null) {
      // Prepara los datos. Si la contraseña está vacía, no la envía.
      final Map<String, dynamic> dataToUpdate = {
        'username': result['username'],
        'email': result['email'],
        'first_name': result['first_name'],
        'last_name': result['last_name'],
      };

      if (result['password'] != null && result['password']!.isNotEmpty) {
        dataToUpdate['password'] = result['password'];
      }

      try {
        await _userService.updateUser(token, user.id, dataToUpdate);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario actualizado'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchData(); // Refresca la lista
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar usuario: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Muestra diálogo de confirmación y elimina un usuario
  Future<void> _deleteUser(User user, String token) async {
    // CORRECCIÓN 2/3:
    // (Lógica movida) Se obtiene el ID del usuario actual ANTES del diálogo.
    final currentUserId = context.read<AuthProvider>().user?.id;

    if (user.id == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes eliminarte a ti mismo.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final bool didConfirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar Eliminación'),
            content: Text(
              '¿Estás seguro de que quieres eliminar a ${user.username}?',
            ),
            actions: [
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ) ??
        false;

    if (didConfirm && mounted) {
      try {
        await _userService.deleteUser(token, user.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario eliminado'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchData(); // Refresca la lista
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // CORRECCIÓN 3/3:
    // Cambiado de 'accessToken' a 'token'
    final String? token = context.watch<AuthProvider>().token;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Usuarios'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchData),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar datos: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          if (token == null) {
            return const Center(
              child: Text(
                'No autorizado. Token no encontrado.',
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          final List<User> users = snapshot.data!['users'];
          final List<Role> roles = snapshot.data!['roles'];

          return _buildUserListView(users, roles, token);
        },
      ),
    );
  }

  Widget _buildUserListView(List<User> users, List<Role> roles, String token) {
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final roleName = user.role?.name ?? 'Cliente';
        final roleColor = roleName == 'Admin'
            ? Colors.red[100]
            : Colors.blue[50];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: roleColor,
          child: ListTile(
            leading: CircleAvatar(child: Text(user.username[0].toUpperCase())),
            title: Text(user.username),
            subtitle: Text(user.email),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Chip para mostrar el rol
                Chip(
                  label: Text(roleName, style: const TextStyle(fontSize: 12)),
                  padding: const EdgeInsets.all(4),
                ),
                const SizedBox(width: 8),

                // Botón para editar Rol
                IconButton(
                  icon: Icon(Icons.security, color: Colors.blueGrey[800]),
                  tooltip: 'Editar Rol',
                  onPressed: () => _showEditRoleDialog(user, roles, token),
                ),

                // Botón para editar Usuario
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blueGrey[700]),
                  tooltip: 'Editar Usuario',
                  onPressed: () => _showEditUserDialog(user, token),
                ),

                // Botón para eliminar Usuario
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  tooltip: 'Eliminar Usuario',
                  onPressed: () => _deleteUser(user, token),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
