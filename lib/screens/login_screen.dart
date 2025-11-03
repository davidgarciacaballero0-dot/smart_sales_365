import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartsales365/providers/auth_provider.dart';
import 'package:smartsales365/screens/register_screen.dart'; // ¡Importante!

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // 1. VARIABLE DE ESTADO AÑADIDA
  bool _isPasswordObscured = true;

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    bool success = await authProvider.login(
      _usernameController.text,
      _passwordController.text,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Error desconocido'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

                // 2. TEXTFORMFIELD DE CONTRASEÑA ACTUALIZADO
                TextFormField(
                  controller: _passwordController,
                  obscureText: _isPasswordObscured, // Usa la variable
                  decoration: InputDecoration(
                    // Se quita 'const'
                    labelText: 'Contraseña',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      // ¡AÑADIDO!
                      icon: Icon(
                        _isPasswordObscured
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordObscured = !_isPasswordObscured;
                        });
                      },
                    ),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Ingrese su contraseña' : null,
                ),
                const SizedBox(height: 30),

                Consumer<AuthProvider>(
                  builder: (context, auth, child) {
                    // Actualizado para usar el estado 'loading'
                    if (auth.status == AuthStatus.loading) {
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

                // 3. BOTÓN DE REGISTRO AÑADIDO
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const RegisterScreen(),
                      ),
                    );
                  },
                  child: const Text('¿No tienes una cuenta? Regístrate'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
