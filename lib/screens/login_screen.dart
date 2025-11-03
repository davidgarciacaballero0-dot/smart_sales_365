import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartsales365/providers/auth_provider.dart'; // Ajusta la ruta

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // (Para pruebas rápidas, puedes pre-llenar esto)
  // @override
  // void initState() {
  //   super.initState();
  //   _usernameController.text = 'tu_usuario_admin';
  //   _passwordController.text = 'tu_contraseña';
  // }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    bool success = await authProvider.login(
      _usernameController.text,
      _passwordController.text,
    );

    if (!success && mounted) {
      // Si falló, muestra el error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Error desconocido'),
          backgroundColor: Colors.red,
        ),
      );
    }
    // Si tuvo éxito, el AuthWrapper nos moverá automáticamente
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'SmartSales365',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Usuario',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Ingrese su usuario' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Ingrese su contraseña' : null,
                ),
                const SizedBox(height: 30),

                // Consumer para mostrar el botón o el loading
                Consumer<AuthProvider>(
                  builder: (context, auth, child) {
                    if (auth.status == AuthStatus.uninitialized) {
                      return const CircularProgressIndicator();
                    }
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitLogin,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blueGrey[700],
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Ingresar',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    );
                  },
                ),
                // (Aquí irá el botón de registro en el futuro)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
