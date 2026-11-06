import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/product.dart';

/// Shares product information, with a copy fallback on unsupported platforms.
Future<void> shareProduct(BuildContext context, BoutiqueProduct product) async {
  final message =
      '${product.name}\n'
      '${product.formatAmount(product.price)}\n'
      '${product.seller}\n'
      'Roni • #${product.id}';
  final box = context.findRenderObject();
  final origin = box is RenderBox && box.hasSize
      ? box.localToGlobal(Offset.zero) & box.size
      : null;
  try {
    final result = await Share.share(
      message,
      subject: product.name,
      sharePositionOrigin: origin,
    );
    if (result.status != ShareResultStatus.unavailable) return;
  } catch (_) {
    // Some browsers and desktop platforms cannot open a native share sheet.
  }
  if (!context.mounted) return;
  try {
    await Clipboard.setData(ClipboardData(text: message));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('زانیاری بەرهەمەکە کۆپی کرا، بۆ هاوڕێکەت بینێرە'),
        ),
      );
  } catch (_) {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('هاوبەشکردن لەگەڵ هاوڕێکان'),
        content: SelectableText(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('داخستن'),
          ),
        ],
      ),
    );
  }
}
