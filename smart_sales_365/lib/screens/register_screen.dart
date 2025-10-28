// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_sales_365/providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  static const String routeName = '/register';
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _password2Controller = TextEditingController();

  bool _obscurePass1 = true;
  bool _obscurePass2 = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _password2Controller.dispose();
    super.dispose();
  }

  // --- Función de Registro (Actualizada) ---
  Future<void> _submitRegister() async {
    // 1. Validar el formulario
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final authProvider = context.read<AuthProvider>();

    // 2. Llamar al método register del provider
    final bool registerSuccess = await authProvider.register(
      username: _usernameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      password2: _password2Controller.text,
    );

    // 3. Manejar el resultado
    if (registerSuccess) {
      // Si el registro es exitoso, el AuthProvider automáticamente
      // hará login y el AuthWrapper nos llevará a HomeScreen.
      // Podemos simplemente cerrar esta pantalla de registro.
      if (mounted) {
        Navigator.of(
          context,
        ).pop(); // Volver a la pantalla de Login (que será reemplazada por Home)
      }
    } else {
      // Si falló, mostrar el error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.errorMessage.isNotEmpty
                  ? authProvider.errorMessage
                  : 'Error al registrar la cuenta',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Escuchamos el estado de carga
    final bool isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Text(
                  'Completa tus datos',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 30),

                // Campo de Username
                TextFormField(
                  controller: _usernameController,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de Usuario',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  enabled: !isLoading,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa un nombre de usuario';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Campo de Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  enabled: !isLoading,
                  validator: (value) {
                    if (value == null ||
                        !value.contains('@') ||
                        !value.contains('.')) {
                      return 'Ingresa un email válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Campo de Contraseña
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePass1,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePass1 ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePass1 = !_obscurePass1;
                        });
                      },
                    ),
                  ),
                  enabled: !isLoading,
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Campo de Confirmar Contraseña
                TextFormField(
                  controller: _password2Controller,
                  obscureText: _obscurePass2,
                  decoration: InputDecoration(
                    labelText: 'Confirmar Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePass2 ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePass2 = !_obscurePass2;
                        });
                      },
                    ),
                  ),
                  enabled: !isLoading,
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Botón de Registrarse
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        // Llamamos a nuestra función actualizada
                        onPressed: _submitRegister,
                        child: const Text(
                          'Registrarse',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
