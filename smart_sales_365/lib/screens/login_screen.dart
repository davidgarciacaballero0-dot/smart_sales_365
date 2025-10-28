// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_sales_365/screens/register_screen.dart';
import 'package:smart_sales_365/providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  static const String routeName = '/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscureText = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- Función de Login (Actualizada) ---
  Future<void> _submitLogin() async {
    // 1. Validar el formulario
    if (!(_formKey.currentState?.validate() ?? false)) {
      return; // Si no es válido, no hacer nada
    }

    // Usamos context.read() dentro de un callback/función
    final authProvider = context.read<AuthProvider>();

    // 2. Llamar al método login del provider
    final bool loginSuccess = await authProvider.login(
      _usernameController.text,
      _passwordController.text,
    );

    // 3. Mostrar error si falló el login
    // El AuthWrapper se encargará de navegar a HomeScreen si fue exitoso
    if (!loginSuccess && mounted) {
      // 'mounted' comprueba si el widget todavía está en pantalla
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage.isNotEmpty
                ? authProvider.errorMessage
                : 'Error al iniciar sesión',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Usamos context.watch para que la UI se reconstruya
    // cuando cambie el estado de 'isLoading'
    final bool isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 100),
                Text(
                  'SmartSales365',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bienvenido',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 40),

                // Campo de Usuario/Email
                TextFormField(
                  controller: _usernameController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Usuario o Email',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  enabled: !isLoading,
                  // Validación
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor, ingresa tu usuario o email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Campo de Contraseña
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscureText,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                  ),
                  enabled: !isLoading,
                  // Validación
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingresa tu contraseña';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Botón de Login
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
                        onPressed: _submitLogin,
                        child: const Text(
                          'Ingresar',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),

                const SizedBox(height: 16),

                // Botón de Registro
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          Navigator.of(
                            context,
                          ).pushNamed(RegisterScreen.routeName);
                        },
                  child: const Text('¿No tienes cuenta? Regístrate'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
