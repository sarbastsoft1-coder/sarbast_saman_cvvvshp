import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routes/boutique_routes.dart';
import '../../core/theme/boutique_colors.dart';
import '../../features/auth/auth_screen.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/checkout_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/orders_provider.dart';
import '../../services/commerce_api.dart';
import '../../widgets/product_card.dart';
import '../../widgets/store_components.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _form = GlobalKey<FormState>();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  bool _submitting = false;
  String? _selectedAddress;
  @override
  void initState() {
    super.initState();
    final saved = context.read<CustomerProvider>().defaultAddress;
    if (saved != null) {
      _selectedAddress = saved.id;
      _address.text = saved.address;
      _phone.text = saved.phone;
    }
    // Ask the server what the bag costs as soon as the screen opens, if there
    // is a session to ask with.
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncServerQuote());
  }

  @override
  void dispose() {
    _address.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _syncServerQuote() async {
    if (!mounted) return;
    if (!context.read<AuthProvider>().isSignedIn) return;
    await context.read<CheckoutProvider>().refreshQuote(
      context.read<CartProvider>(),
    );
  }

  Future<void> _signIn() async {
    final signedIn = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const AuthScreen()));
    if (signedIn == true) await _syncServerQuote();
  }

  /// Saved addresses are identified by server ids, so only a numeric id is sent.
  int? get _serverAddressId => int.tryParse(_selectedAddress ?? '');

  void _selectAddress(String id) {
    final value = context.read<CustomerProvider>().addresses.firstWhere(
      (a) => a.id == id,
    );
    setState(() {
      _selectedAddress = id;
      _address.text = value.address;
      _phone.text = value.phone;
    });
  }

  Future<void> _confirm() async {
    if (_submitting || !_form.currentState!.validate()) return;
    final cart = context.read<CartProvider>();
    if (cart.isEmpty) return;
    if (cart.hasMixedCurrencies) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تکایە پێش تەواوکردنی داواکاری بەرهەمی بە دراوی جیاواز لاببە.',
          ),
        ),
      );
      return;
    }
    setState(() => _submitting = true);

    final auth = context.read<AuthProvider>();
    final checkout = context.read<CheckoutProvider>();
    final orders = context.read<OrdersProvider>();

    // Signed in: the order is real. Stock, discounts and the total are decided
    // by the server, so the numbers the device held are display-only.
    if (auth.isSignedIn) {
      final purchasedLines = List<CartLine>.of(cart.lines);
      final outcome = await checkout.placeOrder(
        cart: cart,
        address: _address.text.trim(),
        phone: normalizePhone(_phone.text),
        addressId: _serverAddressId,
      );
      if (!mounted) return;
      setState(() => _submitting = false);

      if (outcome == CheckoutOutcome.placed) {
        final placed = checkout.placedOrder!;
        final order = orders.addOrder(
          items: purchasedLines,
          serverOrderNumber: placed.orderNumber.isEmpty
              ? '${placed.id}'
              : placed.orderNumber,
          serverId: placed.id,
          total: placed.total,
          deliveryFee: placed.deliveryFee,
          discount: placed.discount,
          address: placed.shippingAddress,
          phone: normalizePhone(_phone.text),
          paymentMethod: 'cash',
        );
        cart.clear();
        await Future.wait([orders.pendingSave, cart.pendingSave]);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '\u062f\u0627\u0648\u0643\u0627\u0631\u06cc\u06d5\u06a9\u06d5 \u062a\u06c6\u0645\u0627\u0631\u06a9\u0631\u0627 \u2713',
            ),
          ),
        );
        Navigator.of(
          context,
        ).pushReplacementNamed(BoutiqueRoutes.orderConfirmed, arguments: order);
        return;
      }

      if (outcome == CheckoutOutcome.needsSignIn) {
        await _signIn();
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(checkout.error ?? 'نەتوانرا داواکارییەکە تەواو بکرێت.'),
        ),
      );
      return;
    }

    // Not signed in: a device-local demonstration order. It is labelled as such
    // in the UI; no payment is taken and nothing is shipped.
    final order = orders.addOrder(
      items: cart.lines,
      total: cart.total,
      deliveryFee: cart.effectiveDeliveryFee,
      discount: cart.discountAmount,
      address: _address.text.trim(),
      phone: normalizePhone(_phone.text),
      paymentMethod: 'cash',
    );
    cart.clear();
    await Future.wait([orders.pendingSave, cart.pendingSave]);
    if (!mounted) return;
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          orders.storageFailed || cart.storageFailed
              ? '\u062f\u0627\u0648\u0643\u0627\u0631\u06cc \u0644\u0645 \u0626\u064e\u067e\u062f\u0627 \u062a\u06c6\u0645\u0627\u0631\u06a9\u0631\u0627\u060c \u0628\u06d5\u0644\u0627\u0645 \u067e\u0627\u0634\u06a9\u06c8\u06a9\u0631\u062f\u0646\u06cc \u0644\u06d5 \u0626\u0627\u0645\u06cc\u0631 \u0633\u06d1\u0631\u06a9\u06cc\u062a\u0648\u0648 \u0646\u06d5\u0628\u06cc\u062f\u0627.'
              : '\u062f\u0627\u0648\u0643\u0627\u0631\u06cc \u062a\u0627\u0642\u06cc\u06a9\u0631\u062f\u0646\u06d5\u0648\u0645 \u062a\u06c6\u0645\u0627\u0631\u06a9\u0631\u0627',
        ),
      ),
    );
    Navigator.of(
      context,
    ).pushReplacementNamed(BoutiqueRoutes.orderConfirmed, arguments: order);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final customer = context.watch<CustomerProvider>();
    final auth = context.watch<AuthProvider>();
    final checkout = context.watch<CheckoutProvider>();
    final busy = _submitting || checkout.submitting;

    // The server's numbers win when a quote has been fetched; otherwise the
    // locally held estimate is shown and clearly marked as an estimate.
    final quote = checkout.quote;
    String format(num value) => quote != null
        ? '\$${value.toStringAsFixed(2)}'
        : cart.formatAmount(value);
    return Scaffold(
      backgroundColor: BoutiqueColors.white,
      appBar: AppBar(
        title: const Text('تەواوکردنی داواکاری'),
        backgroundColor: BoutiqueColors.white,
      ),
      body: cart.isEmpty && !_submitting
          ? StoreEmpty(
              title: 'سەبەتەکەت بەتاڵە',
              message: 'پێش تەواوکردنی داواکاری بەرهەم هەڵبژێرە.',
              icon: Icons.shopping_bag_outlined,
              action: GoldButton(
                label: 'بینینی بەرهەمەکان',
                icon: Icons.explore_outlined,
                expand: false,
                onPressed: () => BoutiqueRoutes.openTab(context, 1),
              ),
            )
          : Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  const _StepProgress(),
                  const SizedBox(height: 14),
                  if (auth.isSignedIn)
                    const StoreNotice(
                      'تۆمارکردنی ڕاستەقینە • نرخ و بەردەستی لەلایەن فروشگا دیاری دەکرێن.',
                      icon: Icons.verified_user_outlined,
                    )
                  else
                    const StoreNotice(
                      'ئەمە تاقیکردنەوەی ناوخۆییە • بۆ داواکاریی ڕاستەقینە چوونەژوورەوە بکە',
                      icon: Icons.info_outline_rounded,
                    ),
                  if (checkout.error != null) ...[
                    const SizedBox(height: 12),
                    _CheckoutWarning(message: checkout.error!),
                  ],
                  const SizedBox(height: 22),
                  const RoniSectionHeader(
                    title: '١. ناونیشانی گەیاندن',
                    padding: EdgeInsets.only(bottom: 10),
                  ),
                  if (customer.addresses.isNotEmpty) ...[
                    for (final address in customer.addresses)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _OptionCard(
                          selected: _selectedAddress == address.id,
                          icon: Icons.home_work_outlined,
                          title: address.label,
                          subtitle: address.address,
                          onTap: () => _selectAddress(address.id),
                        ),
                      ),
                    GhostButton(
                      label: 'زیادکردنی ناونیشانی نوێ',
                      icon: Icons.add_location_alt_outlined,
                      height: 48,
                      onPressed: () => Navigator.pushNamed(
                        context,
                        BoutiqueRoutes.addresses,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    key: const Key('checkout-address'),
                    controller: _address,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'ناونیشانی تەواو',
                      hintText: 'شار، گەڕەک، شەقام و ژمارەی ماڵ',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    validator: (v) => (v ?? '').trim().length < 10
                        ? 'ناونیشانی تەواو بنووسە (لانیکەم ١٠ پیت)'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    key: const Key('checkout-phone'),
                    controller: _phone,
                    textDirection: TextDirection.ltr,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'ژمارەی مۆبایل',
                      hintText: '07xxxxxxxxx',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: validatePhone,
                  ),
                  const SizedBox(height: 24),
                  const RoniSectionHeader(
                    title: '٢. شێوازی گەیاندن',
                    padding: EdgeInsets.only(bottom: 10),
                  ),
                  // Only standard delivery is priced by the app today, so the
                  // card shows the fee the cart already works out.
                  _OptionCard(
                    selected: true,
                    icon: Icons.local_shipping_outlined,
                    title: 'گەیاندنی ئاسایی',
                    subtitle: cart.effectiveDeliveryFee == 0
                        ? 'بێبەرامبەر'
                        : cart.formatAmount(cart.effectiveDeliveryFee),
                  ),
                  const SizedBox(height: 24),
                  const RoniSectionHeader(
                    title: '٣. شێوازی پارەدان',
                    padding: EdgeInsets.only(bottom: 10),
                  ),
                  const _OptionCard(
                    selected: true,
                    icon: Icons.payments_outlined,
                    title: 'پارەدان لە کاتی وەرگرتن',
                    subtitle: 'تەنها بۆ تاقیکردنەوە • کارتی بانکی بەردەست نییە',
                  ),
                  const SizedBox(height: 10),
                  const _OptionCard(
                    selected: false,
                    enabled: false,
                    icon: Icons.credit_card_off_outlined,
                    title: 'کارتی بانکی',
                    subtitle: 'ئەم سەردەمە بەردەست نییە',
                  ),
                  const SizedBox(height: 24),
                  const RoniSectionHeader(
                    title: '٤. پوختەی داواکاری',
                    padding: EdgeInsets.only(bottom: 10),
                  ),
                  RoniCard(
                    child: Column(
                      children: [
                        for (final line in cart.lines)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: ProductArtwork(product: line.product),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${line.product.name} × ${line.quantity}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontFamily: 'Vazirmatn',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: BoutiqueColors.charcoal,
                                        ),
                                      ),
                                      if (line.variantLabel.isNotEmpty)
                                        Text(
                                          line.variantLabel,
                                          style: const TextStyle(
                                            fontFamily: 'Vazirmatn',
                                            fontSize: 11,
                                            color: BoutiqueColors.muted,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  line.product.formatAmount(line.subtotal),
                                  style: const TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: BoutiqueColors.charcoal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Divider(height: 1),
                        ),
                        // When a server quote is available these are the
                        // numbers the backend will actually charge.
                        _row(
                          'کۆی بەرهەمەکان',
                          format(quote?.subtotal ?? cart.subtotal),
                        ),
                        if ((quote?.discount ?? cart.discountAmount) > 0)
                          _row(
                            'داشکاندن'
                                '${quote?.couponCode != null ? ' (${quote!.couponCode})' : ''}',
                            '−${format(quote?.discount ?? cart.discountAmount)}',
                            valueColor: BoutiqueColors.rose,
                          ),
                        _row(
                          'گەیاندن',
                          (quote?.deliveryFee ?? cart.effectiveDeliveryFee) == 0
                              ? 'بێبەرامبەر'
                              : format(
                                  quote?.deliveryFee ??
                                      cart.effectiveDeliveryFee,
                                ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(height: 1),
                        ),
                        _row(
                          'کۆی گشتی',
                          format(quote?.total ?? cart.total),
                          bold: true,
                        ),
                        if (checkout.quoting) ...[
                          const SizedBox(height: 10),
                          const Row(
                            children: [
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'نرخەکان لەلایەن فروشگا دیاری دەکرێن…',
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 11,
                                  color: BoutiqueColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: cart.isEmpty && !_submitting
          ? null
          : _CheckoutFooter(
              cart: cart,
              quote: quote,
              auth: auth,
              busy: busy,
              format: format,
              onSignIn: busy ? null : _signIn,
              onConfirm: busy ? null : _confirm,
            ),
    );
  }

  Widget _row(
    String label,
    String value, {
    bool bold = false,
    Color? valueColor,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 13,
              color: bold ? BoutiqueColors.charcoal : BoutiqueColors.muted,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: bold ? 19 : 14,
            fontWeight: FontWeight.w800,
            color: valueColor ?? BoutiqueColors.charcoal,
          ),
        ),
      ],
    ),
  );
}

/// Four-step marker for address → delivery → payment → review.
class _StepProgress extends StatelessWidget {
  const _StepProgress();
  static const steps = ['ناونیشان', 'گەیاندن', 'پارەدان', 'پوختە'];
  @override
  Widget build(BuildContext context) => RoniCard(
    shadow: false,
    color: BoutiqueColors.goldWash,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
    child: Row(
      children: [
        for (var i = 0; i < steps.length; i++)
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    if (i > 0)
                      const Expanded(
                        child: SizedBox(
                          height: 2,
                          child: ColoredBox(color: BoutiqueColors.gold),
                        ),
                      ),
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        gradient: BoutiqueColors.goldGradient,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: BoutiqueColors.white,
                        ),
                      ),
                    ),
                    if (i < steps.length - 1)
                      const Expanded(
                        child: SizedBox(
                          height: 2,
                          child: ColoredBox(color: BoutiqueColors.gold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  steps[i],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: BoutiqueColors.charcoal,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

/// Radio-style card used for addresses, delivery and payment.
class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.enabled = true,
  });
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool enabled;
  @override
  Widget build(BuildContext context) => RoniCard(
    onTap: enabled ? onTap : null,
    color: selected ? BoutiqueColors.goldWash : BoutiqueColors.card,
    borderColor: selected ? BoutiqueColors.gold : BoutiqueColors.border,
    padding: const EdgeInsets.all(14),
    child: Opacity(
      opacity: enabled ? 1 : .6,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: selected ? BoutiqueColors.goldGradient : null,
              color: selected ? null : BoutiqueColors.beige,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 19,
              color: selected ? BoutiqueColors.white : BoutiqueColors.muted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: BoutiqueColors.charcoal,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 11,
                    height: 1.45,
                    color: BoutiqueColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            selected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: selected ? BoutiqueColors.goldDeep : BoutiqueColors.border,
            size: 21,
          ),
        ],
      ),
    ),
  );
}

/// Shown when the server reports a stock, price or coupon problem that the
/// customer needs to act on before the order can go through.
class _CheckoutWarning extends StatelessWidget {
  const _CheckoutWarning({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: BoutiqueColors.rose.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: BoutiqueColors.rose.withValues(alpha: .35)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.warning_amber_rounded,
          size: 20,
          color: BoutiqueColors.rose,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 12.5,
              color: BoutiqueColors.rose,
              height: 1.5,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Sticky order bar pinned to the bottom of checkout.
///
/// The running total and the confirm action stay reachable on short screens
/// instead of scrolling away with the form.
class _CheckoutFooter extends StatelessWidget {
  const _CheckoutFooter({
    required this.cart,
    required this.quote,
    required this.auth,
    required this.busy,
    required this.format,
    required this.onSignIn,
    required this.onConfirm,
  });

  final CartProvider cart;
  final CartQuote? quote;
  final AuthProvider auth;
  final bool busy;
  final String Function(num) format;
  final VoidCallback? onSignIn;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final total = quote?.total ?? cart.total;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: BoutiqueColors.white,
        border: Border(top: BorderSide(color: BoutiqueColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text(
                    'کۆی گشتی',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: BoutiqueColors.muted,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    format(total),
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (!auth.isSignedIn) ...[
                GhostButton(
                  key: const Key('checkout-sign-in'),
                  label: 'چوونەژوورەوە بۆ داواکاریی ڕاستەقینە',
                  icon: Icons.login_rounded,
                  height: 46,
                  onPressed: onSignIn,
                ),
                const SizedBox(height: 8),
              ],
              GoldButton(
                key: const Key('confirm-order'),
                label: busy
                    ? 'پاشەکەوتکردن...'
                    : auth.isSignedIn
                    ? 'داواکاریکردن'
                    : 'تۆمارکردنی داواکاریی تاقیکردنەوە',
                icon: Icons.check_rounded,
                subtitle: format(total),
                onPressed: onConfirm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
