import 'package:flutter/foundation.dart';

import '../services/commerce_api.dart';
import 'cart_provider.dart';

/// Outcome of a checkout attempt, so the UI can react without parsing strings.
enum CheckoutOutcome { placed, needsSignIn, failed, outOfStock }

/// Drives the real checkout flow against the Laravel backend.
///
/// Nothing here computes a price: [quote] asks the server what the cart costs
/// and [placeOrder] lets the server decide the final total. A client that lies
/// about prices simply gets the server's numbers back.
class CheckoutProvider extends ChangeNotifier {
  CheckoutProvider({required CommerceApi api}) : _api = api;

  final CommerceApi _api;

  CartQuote? _quote;
  PlacedOrder? placedOrder;
  int _quoteGeneration = 0;
  bool _disposed = false;
  bool _quoting = false;
  bool _submitting = false;
  String? _error;
  String? _couponCode;
  CheckoutOutcome? _lastOutcome;

  /// The server-priced version of the current cart, when one has been fetched.
  CartQuote? get quote => _quote;
  bool get quoting => _quoting;
  bool get submitting => _submitting;
  String? get error => _error;
  String? get couponCode => _couponCode;
  CheckoutOutcome? get lastOutcome => _lastOutcome;

  /// True when the cart is priced by the server rather than estimated locally.
  bool get hasServerPricing => _quote != null;

  List<({int productId, int quantity})> _itemsOf(CartProvider cart) => [
    for (final line in cart.lines)
      (productId: line.product.id, quantity: line.quantity),
  ];

  /// True when the cart still holds exactly the lines a quote was requested
  /// for. Records compare structurally, so ordering does not matter.
  static bool _sameItems(
    List<({int productId, int quantity})> a,
    List<({int productId, int quantity})> b,
  ) {
    if (a.length != b.length) return false;
    final remaining = [...b];
    for (final item in a) {
      final index = remaining.indexWhere(
        (other) =>
            other.productId == item.productId &&
            other.quantity == item.quantity,
      );
      if (index < 0) return false;
      remaining.removeAt(index);
    }
    return true;
  }

  /// Fetches the authoritative price for the current cart.
  ///
  /// Safe to call on every cart change; only the latest request may update
  /// pricing, even when coupon responses arrive out of order.
  Future<void> refreshQuote(CartProvider cart, {String? couponCode}) async {
    final generation = ++_quoteGeneration;
    _quote = null;
    _couponCode = null;
    _error = null;
    if (cart.isEmpty) {
      _quoting = false;
      _quote = null;
      _couponCode = null;
      notifyListeners();
      return;
    }

    _quoting = true;
    _error = null;
    notifyListeners();

    final requested = _itemsOf(cart);
    final requestedCoupon =
        couponCode ?? cart.appliedCoupon?.code;

    try {
      final result = await _api.quote(
        items: requested,
        couponCode: requestedCoupon,
      );

      // The cart may have changed while this was in flight; a quote for
      // different lines is worse than no quote at all.
      if (generation != _quoteGeneration ||
          !_sameItems(requested, _itemsOf(cart))) {
        return;
      }

      _quote = result;
      _couponCode = result.couponCode;
      _error =
          result.couponError ??
          (result.warnings.isEmpty ? null : result.warnings.join('\n'));
    } on CommerceException catch (e) {
      if (generation != _quoteGeneration) return;
      if (e is AuthExpired) {
        _quote = null;
        _lastOutcome = CheckoutOutcome.needsSignIn;
      } else {
        _error = e.message;
      }
    } finally {
      if (generation == _quoteGeneration) {
        _quoting = false;
        notifyListeners();
      }
    }
  }

  /// Places the order. The server recomputes every total, so the values held by
  /// the cart are only used for display.
  Future<CheckoutOutcome> placeOrder({
    required CartProvider cart,
    required String address,
    required String phone,
    int? addressId,
    String paymentMethod = 'cash',
  }) async {
    if (_submitting) return CheckoutOutcome.failed;
    if (cart.isEmpty) {
      _error = 'Your bag is empty.';
      notifyListeners();
      return CheckoutOutcome.failed;
    }

    placedOrder = null;
    _submitting = true;
    _error = null;
    _lastOutcome = null;
    notifyListeners();

    try {
      placedOrder = await _api.checkout(
        items: _itemsOf(cart),
        shippingAddress: address,
        phone: phone,
        paymentMethod: paymentMethod,
        addressId: addressId,
        couponCode: _couponCode,
      );

      ++_quoteGeneration;
      _quoting = false;
      _quote = null;
      _couponCode = null;
      _lastOutcome = CheckoutOutcome.placed;
      return CheckoutOutcome.placed;
    } on AuthExpired {
      _lastOutcome = CheckoutOutcome.needsSignIn;
      _error = 'Please sign in to complete your order.';
      return CheckoutOutcome.needsSignIn;
    } on CommerceException catch (e) {
      // Stock problems and price changes come back as a readable message.
      _error = e.message;
      _lastOutcome = CheckoutOutcome.failed;
      return CheckoutOutcome.failed;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_quoteGeneration;
    super.dispose();
  }

  void reset() {
    ++_quoteGeneration;
    _quoting = false;
    placedOrder = null;
    _quote = null;
    _couponCode = null;
    _error = null;
    _lastOutcome = null;
    notifyListeners();
  }
}
