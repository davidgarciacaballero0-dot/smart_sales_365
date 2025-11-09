// lib/screens/admin/admin_user_list_screen.dart

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
  List<User> _users = [];
  List<Role> _roles = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Usamos addPostFrameCallback para acceder al context de Provider de forma segura
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  /// Carga los usuarios y roles desde la API
  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // CORRECCIÓN 1/3:
    final token = authProvider.accessToken; // Antes: .token

    if (token == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = "No autorizado. Por favor, inicie sesión de nuevo.";
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      // Ejecutamos ambas peticiones en paralelo para más eficiencia
      final results = await Future.wait([
        _userService.getUsers(token),
        _userService.getRoles(token),
      ]);

      if (mounted) {
        setState(() {
          _users = results[0] as List<User>;
          _roles = results[1] as List<Role>;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Error al cargar datos: ${e.toString()}";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData, // Botón para recargar los datos
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  /// Construye el cuerpo principal de la pantalla
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_users.isEmpty) {
      return const Center(child: Text('No se encontraron usuarios.'));
    }

    // Si todo está bien, muestra la lista
    return ListView.builder(
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(
              user.fullName.isNotEmpty ? user.fullName : user.username,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.email),
                const SizedBox(height: 4),
                Chip(
                  label: Text(user.role.name),
                  backgroundColor: _getRoleColor(
                    user.role.name,
                  ), // Color según el rol
                  labelStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botón Editar Rol
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    // Solo permite editar si tenemos roles cargados
                    if (_roles.isNotEmpty) {
                      _showEditRoleDialog(user);
                    }
                  },
                ),
                // Botón Eliminar Usuario
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    _confirmDeleteUser(user);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Devuelve un color basado en el nombre del rol
  Color _getRoleColor(String roleName) {
    switch (roleName.toLowerCase()) {
      case 'admin':
        return Colors.red.shade700;
      case 'client':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  /// Muestra un diálogo de confirmación antes de eliminar
  void _confirmDeleteUser(User user) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: Text(
            '¿Estás seguro de que deseas eliminar a ${user.username}? Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(ctx).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar'),
              onPressed: () {
                Navigator.of(ctx).pop(); // Cierra el diálogo
                _deleteUser(user.id); // Ejecuta la eliminación
              },
            ),
          ],
        );
      },
    );
  }

  /// Llama al servicio para eliminar un usuario
  Future<void> _deleteUser(int userId) async {
    // CORRECCIÓN 2/3:
    final token = Provider.of<AuthProvider>(context, listen: false).accessToken;
    if (token == null) return;

    try {
      await _userService.deleteUser(token, userId);

      // Éxito: actualizar la UI
      if (mounted) {
        setState(() {
          _users.removeWhere((user) => user.id == userId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario eliminado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar usuario: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Muestra un diálogo para cambiar el rol del usuario
  void _showEditRoleDialog(User user) {
    // El rol actualmente seleccionado en el diálogo
    int selectedRoleId = user.role.id;

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        // Usamos StatefulBuilder para que el Dropdown pueda actualizar su estado
        // DENTRO del diálogo, sin tener que redibujar toda la pantalla.
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text('Editar Rol de ${user.username}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Selecciona el nuevo rol para este usuario:'),
                  const SizedBox(height: 16),
                  DropdownButton<int>(
                    value: selectedRoleId,
                    isExpanded: true,
                    items: _roles.map((Role role) {
                      return DropdownMenuItem<int>(
                        value: role.id,
                        child: Text(role.name),
                      );
                    }).toList(),
                    onChanged: (int? newValue) {
                      if (newValue != null) {
                        setDialogState(() {
                          selectedRoleId = newValue;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                  },
                ),
                TextButton(
                  child: const Text('Guardar'),
                  onPressed: () {
                    Navigator.of(ctx).pop(); // Cierra el diálogo
                    _updateUserRole(user, selectedRoleId);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Llama al servicio para actualizar el rol de un usuario
  Future<void> _updateUserRole(User user, int newRoleId) async {
    // CORRECCIÓN 3/3:
    final token = Provider.of<AuthProvider>(context, listen: false).accessToken;
    if (token == null) return;

    // Evitar llamadas innecesarias si el rol no cambió
    if (user.role.id == newRoleId) return;

    try {
      await _userService.updateUserRole(token, user.id, newRoleId);

      // Éxito: actualizar la UI
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rol de usuario actualizado'),
            backgroundColor: Colors.green,
          ),
        );
        // Recargamos toda la lista para tener la información más fresca
        _loadData();
      }
    } catch (e) {
      // Error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar rol: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
