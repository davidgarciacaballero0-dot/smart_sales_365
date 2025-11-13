// lib/screens/cart_screen.dart

// ignore_for_file: use_build_context_synchronously, avoid_print, deprecated_member_use, depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartsales365/models/cart_item_model.dart';
import 'package:smartsales365/providers/auth_provider.dart';
import 'package:smartsales365/providers/cart_provider.dart';
import 'package:smartsales365/providers/payment_provider.dart';
import 'package:smartsales365/utils/error_handler.dart';
// import 'package:url_launcher/url_launcher.dart';
import 'package:smartsales365/screens/checkout_confirmation_screen.dart';

/// Pantalla del carrito de compras
/// Conectada al backend mediante CartProvider
///
/// Características:
/// - Muestra items del carrito con imágenes
/// - Botones +/- para ajustar cantidades
/// - Eliminar items individualmente
/// - Cálculo de totales desde backend
/// - Botón de checkout que crea orden y redirige a Stripe
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _shippingAddressController = TextEditingController();
  final _shippingPhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Cargar carrito al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCart();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recargar carrito cada vez que se vuelve a esta pantalla
    // Esto asegura que siempre veamos el estado actual del carrito
    _loadCart();
  }

  void _loadCart() async {
    final authProvider = context.read<AuthProvider>();
    final cartProvider = context.read<CartProvider>();

    if (authProvider.token == null) {
      return;
    }

    await cartProvider.loadCart(authProvider.token!);

    // Verificar si hay error de token expirado
    if (mounted && cartProvider.errorMessage == 'TOKEN_EXPIRED') {
      _handleTokenExpired();
    }
  }

  void _handleTokenExpired() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Tu sesión ha expirado. Por favor, inicia sesión nuevamente',
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 4),
      ),
    );

    // Logout y redirigir a login
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        final authProvider = context.read<AuthProvider>();
        final cartProvider = context.read<CartProvider>();
        authProvider.logout();
        cartProvider.reset();
        Navigator.of(context).pushReplacementNamed('/login');
      }
    });
  }

  @override
  void dispose() {
    _shippingAddressController.dispose();
    _shippingPhoneController.dispose();
    super.dispose();
  }

  /// Procesa el checkout: crea orden y abre Stripe
  Future<void> _processCheckout() async {
    final authProvider = context.read<AuthProvider>();
    final cartProvider = context.read<CartProvider>();
    final paymentProvider = context.read<PaymentProvider>();

    if (authProvider.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para continuar'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validar que hay items en el carrito
    if (!cartProvider.hasItems) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El carrito está vacío'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Mostrar diálogo para ingresar datos de envío
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _ShippingInfoDialog(
        addressController: _shippingAddressController,
        phoneController: _shippingPhoneController,
      ),
    );

    if (result == null) return; // Usuario canceló

    if (paymentProvider.isProcessing) return; // Guardar idempotencia

    await paymentProvider.processCheckout(
      token: authProvider.token!,
      cartProvider: cartProvider,
      shippingAddress: result['address']!,
      shippingPhone: result['phone']!,
    );

    if (!mounted) return;

    if (paymentProvider.status == PaymentStatus.error) {
      ErrorHandler.showError(
        context,
        paymentProvider.errorMessage ?? 'Error en el checkout',
        prefix: 'Checkout',
      );
      return;
    }

    // Ir a pantalla de confirmación y acciones de pago (pantalla completa)
    if (paymentProvider.lastOrder != null) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CheckoutConfirmationScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrito de Compras'),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              if (cart.hasItems) {
                return IconButton(
                  icon: const Icon(Icons.delete_sweep),
                  onPressed: () => _showClearCartDialog(context),
                  tooltip: 'Vaciar carrito',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          // Estado de carga
          if (cartProvider.isLoading && cartProvider.cart == null) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error
          if (cartProvider.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      cartProvider.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadCart,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Carrito vacío
          if (!cartProvider.hasItems) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 100,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tu carrito está vacío',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  const Text('¡Agrega productos para comenzar!'),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.shopping_bag),
                    label: const Text('Ir al catálogo'),
                  ),
                ],
              ),
            );
          }

          // Carrito con items
          final cart = cartProvider.cart!;
          return Column(
            children: [
              // Lista de items
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return _CartItemCard(
                      item: item,
                      onIncrement: () => _incrementItem(item),
                      onDecrement: () => _decrementItem(item),
                      onRemove: () => _removeItem(item),
                    );
                  },
                ),
              ),

              // Resumen y botón de checkout
              _buildCheckoutSection(cart.totalPrice),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCheckoutSection(double totalPrice) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total:', style: Theme.of(context).textTheme.titleLarge),
                Text(
                  '\$${totalPrice.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: context.watch<PaymentProvider>().isProcessing
                    ? null
                    : _processCheckout,
                icon: context.watch<PaymentProvider>().isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.payment),
                label: Text(
                  context.watch<PaymentProvider>().isProcessing
                      ? 'Procesando...'
                      : 'Proceder al pago',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _incrementItem(CartItem item) async {
    final authProvider = context.read<AuthProvider>();
    final cartProvider = context.read<CartProvider>();

    if (authProvider.token == null) return;

    final success = await cartProvider.incrementItem(
      token: authProvider.token!,
      itemId: item.id,
      currentQuantity: item.quantity,
    );

    // Verificar si hay error de token expirado
    if (mounted && !success && cartProvider.errorMessage == 'TOKEN_EXPIRED') {
      _handleTokenExpired();
    }
  }

  Future<void> _decrementItem(CartItem item) async {
    final authProvider = context.read<AuthProvider>();
    final cartProvider = context.read<CartProvider>();

    if (authProvider.token == null) return;

    final success = await cartProvider.decrementItem(
      token: authProvider.token!,
      itemId: item.id,
      currentQuantity: item.quantity,
    );

    // Verificar si hay error de token expirado
    if (mounted && !success && cartProvider.errorMessage == 'TOKEN_EXPIRED') {
      _handleTokenExpired();
    }
  }

  Future<void> _removeItem(CartItem item) async {
    final authProvider = context.read<AuthProvider>();
    final cartProvider = context.read<CartProvider>();

    if (authProvider.token == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Deseas eliminar "${item.product.name}" del carrito?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await cartProvider.removeItem(
        token: authProvider.token!,
        itemId: item.id,
      );

      // Verificar si hay error de token expirado
      if (mounted && !success && cartProvider.errorMessage == 'TOKEN_EXPIRED') {
        _handleTokenExpired();
      }
    }
  }

  Future<void> _showClearCartDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vaciar carrito'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar todos los productos del carrito?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Vaciar'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final authProvider = context.read<AuthProvider>();
      final cartProvider = context.read<CartProvider>();

      if (authProvider.token != null) {
        await cartProvider.clearCart(authProvider.token!);
      }
    }
  }
}

/// Widget para mostrar un item del carrito
class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const _CartItemCard({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Imagen del producto
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: item.product.image != null
                  ? Image.network(
                      item.product.image!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported),
                        );
                      },
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.shopping_bag),
                    ),
            ),
            const SizedBox(width: 12),

            // Información del producto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${item.product.price.toStringAsFixed(2)} c/u',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Subtotal: \$${item.itemPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Controles de cantidad
            Column(
              children: [
                // Botones +/-
                Row(
                  children: [
                    IconButton(
                      onPressed: onDecrement,
                      icon: const Icon(Icons.remove_circle_outline),
                      color: Colors.red,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onIncrement,
                      icon: const Icon(Icons.add_circle_outline),
                      color: Colors.green,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Botón eliminar
                TextButton.icon(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Eliminar'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Diálogo para ingresar información de envío
class _ShippingInfoDialog extends StatefulWidget {
  final TextEditingController addressController;
  final TextEditingController phoneController;

  const _ShippingInfoDialog({
    required this.addressController,
    required this.phoneController,
  });

  @override
  State<_ShippingInfoDialog> createState() => _ShippingInfoDialogState();
}

class _ShippingInfoDialogState extends State<_ShippingInfoDialog> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Información de envío'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: widget.addressController,
              decoration: const InputDecoration(
                labelText: 'Dirección de envío',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa una dirección';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: widget.phoneController,
              decoration: const InputDecoration(
                labelText: 'Teléfono de contacto',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa un teléfono';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop({
                'address': widget.addressController.text.trim(),
                'phone': widget.phoneController.text.trim(),
              });
            }
          },
          child: const Text('Continuar'),
        ),
      ],
    );
  }
}
