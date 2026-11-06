import 'package:flutter/material.dart';
import '../theme/earth_theme.dart';
import '../utils/animations.dart';
import '../widgets/glass_container.dart';
import '../models/models.dart';
import '../localization/string_extension.dart';
import 'main_shell.dart';
import 'dart:math' as math;

class CartScreen extends StatefulWidget {
  final AppState appState;

  const CartScreen({super.key, required this.appState});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen>
    with TickerProviderStateMixin {
  final Map<int, AnimationController> _entryCtrls = {};

  @override
  void initState() {
    super.initState();
    for (final item in widget.appState.cart) {
      _ensureEntryCtrl(item.product.id);
    }
  }

  void _ensureEntryCtrl(int productId) {
    if (_entryCtrls[productId] == null) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
      ctrl.forward();
      _entryCtrls[productId] = ctrl;
    }
  }

  @override
  void dispose() {
    for (final c in _entryCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EarthTheme.warmSand,
      appBar: AppBar(
        backgroundColor: EarthTheme.warmSand,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Text(
              'Your Cart'.tr(context),
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: EarthTheme.forestGreen,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(width: 8),
            if (widget.appState.cart.isNotEmpty)
              PillBadge(
                label: '${widget.appState.cartCount}',
                color: EarthTheme.terracotta,
                textColor: Colors.white,
              ),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.appState,
        builder: (context, _) {
          // Ensure new items get an entry controller
          for (final item in widget.appState.cart) {
            _ensureEntryCtrl(item.product.id);
          }
          // Dispose controllers for removed items
          final ids = widget.appState.cart.map((c) => c.product.id).toSet();
          _entryCtrls.removeWhere((id, c) {
            if (!ids.contains(id)) {
              c.dispose();
              return true;
            }
            return false;
          });

          if (widget.appState.cart.isEmpty) {
            return _buildEmptyCart();
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: _buildCartContent(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [EarthTheme.sageLight, EarthTheme.ochreLight],
              ),
              boxShadow: [
                BoxShadow(
                  color: EarthTheme.sageGreen.withValues(alpha: 0.15),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Center(
              child: Text('🛒', style: TextStyle(fontSize: 56)),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Your cart is empty'.tr(context),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: EarthTheme.forestGreen,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Explore our artisan marketplace and add unique sustainable goods.'.tr(context),
            style: TextStyle(
              fontSize: 13,
              color: EarthTheme.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 22),
          GradientButton(
            label: 'Start Shopping'.tr(context),
            icon: Icons.explore_outlined,
            expanded: false,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent() {
    final subtotal = widget.appState.cartSubtotal;
    const delivery = 4.99;
    final total = subtotal + delivery;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: widget.appState.cart.length,
            itemBuilder: (context, i) {
              final item = widget.appState.cart[i];
              final ctrl = _entryCtrls[item.product.id]!;
              return AnimatedBuilder(
                animation: ctrl,
                builder: (context, child) {
                  final t = ctrl.value;
                  return Opacity(
                    opacity: t,
                    child: Transform.translate(
                      offset: Offset((1 - t) * 60, 0),
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CartItem(
                    item: item,
                    onIncrement: () => widget.appState
                        .changeQty(item.product.id, 1),
                    onDecrement: () => widget.appState
                        .changeQty(item.product.id, -1),
                    onRemove: () => widget.appState
                        .removeFromCart(item.product.id),
                  ),
                ),
              );
            },
          ),
        ),

        // Summary
        Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            border: const Border(
              top: BorderSide(color: EarthTheme.borderLight, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: EarthTheme.forestGreen.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            children: [
              _summaryRow(
                  'Subtotal'.tr(context), '\$${subtotal.toStringAsFixed(2)}'),
              _summaryRow(
                  'Eco Delivery'.tr(context), '\$${delivery.toStringAsFixed(2)}'),
              _summaryRow(
                'Terra Equivalent'.tr(context),
                '🪙 ${(total / widget.appState.terraRate).toStringAsFixed(1)}',
                valueColor: EarthTheme.clayOchre,
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                height: 1,
                color: EarthTheme.borderLight,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total'.tr(context),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: EarthTheme.forestGreen,
                    ),
                  ),
                  AnimatedCounter(
                    value: total,
                    decimals: 2,
                    prefix: '\$',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: EarthTheme.forestGreen,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              GradientButton(
                label:
                    'Checkout • \$${total.toStringAsFixed(2)}',
                icon: Icons.lock_outline_rounded,
                height: 56,
                onPressed: () => _doCheckout(false, total),
              ),
              const SizedBox(height: 8),

              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(EarthTheme.radiusMd),
                  ),
                  side: BorderSide(
                    color: EarthTheme.clayOchre.withValues(alpha: 0.4),
                    width: 1.4,
                  ),
                  foregroundColor: EarthTheme.clayOchre,
                ),
                onPressed: () => _doCheckout(true, total),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🪙'),
                    const SizedBox(width: 6),
                    Text(
                      'Pay with ${(total / widget.appState.terraRate).toStringAsFixed(1)} TERRA',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: EarthTheme.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor ?? EarthTheme.charcoal,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _doCheckout(bool withTokens, double total) async {
    final ok = await widget.appState.checkout(withTokens: withTokens);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Insufficient ${withTokens ? 'TERRA tokens' : 'USD balance'}!'),
          backgroundColor: EarthTheme.warning,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SuccessDialog(orderId: 1000 + math.Random().nextInt(9000)),
    );
  }
}

class _CartItem extends StatefulWidget {
  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const _CartItem({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  State<_CartItem> createState() => _CartItemState();
}

class _CartItemState extends State<_CartItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _qtyCtrl;
  late Animation<double> _qtyScale;

  @override
  void initState() {
    super.initState();
    _qtyCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _qtyScale = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _qtyCtrl, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  void _bump() {
    _qtyCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(EarthTheme.radiusMd),
        border: Border.all(color: EarthTheme.borderLight),
        boxShadow: EarthTheme.subtleShadow,
      ),
      child: Row(
        children: [
          // Image
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  EarthTheme.categoryBg(item.product.category),
                  EarthTheme.categoryBg(item.product.category)
                      .withValues(alpha: 0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Hero(
                tag: 'cart-emoji-${item.product.id}',
                child: Text(
                  item.product.emoji,
                  style: const TextStyle(fontSize: 30),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: EarthTheme.charcoal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.product.seller,
                  style: TextStyle(
                    fontSize: 11,
                    color: EarthTheme.muted,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                AnimatedCounter(
                  value: item.totalPrice,
                  decimals: 2,
                  prefix: '\$',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: EarthTheme.forestGreen,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),

          // Qty controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: EarthTheme.warmSandLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: EarthTheme.borderLight),
            ),
            child: Row(
              children: [
                _qtyBtn(
                  Icons.remove_rounded,
                  onTap: () {
                    widget.onDecrement();
                    _bump();
                  },
                ),
                AnimatedBuilder(
                  animation: _qtyScale,
                  builder: (context, _) {
                    return Container(
                      constraints: const BoxConstraints(minWidth: 24),
                      child: Center(
                        child: Text(
                          '${item.qty}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: EarthTheme.forestGreen,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                _qtyBtn(
                  Icons.add_rounded,
                  isAdd: true,
                  onTap: () {
                    widget.onIncrement();
                    _bump();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, {required VoidCallback onTap, bool isAdd = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          gradient: isAdd
              ? const LinearGradient(
                  colors: [EarthTheme.terracotta, EarthTheme.clayOchre],
                )
              : null,
          color: isAdd ? null : Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: isAdd
              ? null
              : Border.all(color: EarthTheme.border),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 14,
            color: isAdd ? Colors.white : EarthTheme.forestGreen,
          ),
        ),
      ),
    );
  }
}

class _SuccessDialog extends StatefulWidget {
  final int orderId;
  const _SuccessDialog({required this.orderId});

  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _ctrl, curve: EarthTheme.curveOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: EarthTheme.cardShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ConfettiBurst(size: 200),
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              EarthTheme.success,
                              EarthTheme.sageGreen,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: EarthTheme.success
                                  .withValues(alpha: 0.35),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 56,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Order Placed!'.tr(context),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: EarthTheme.forestGreen,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your artisan goods are on their way. You\'ll receive tracking updates soon.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: EarthTheme.muted,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: EarthTheme.sageLight,
                    borderRadius:
                        BorderRadius.circular(EarthTheme.radiusSm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [EarthTheme.forestGreen, EarthTheme.sageGreen],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text('📦', style: TextStyle(fontSize: 18)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #ES-${widget.orderId}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: EarthTheme.forestGreen,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Estimated delivery: 3-5 days',
                            style: TextStyle(
                              fontSize: 11,
                              color: EarthTheme.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                GradientButton(
                  label: 'Continue Shopping'.tr(context),
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () {
                    final nav = Navigator.of(context);
                    if (nav.canPop()) nav.pop();
                    if (nav.canPop()) nav.pop();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
