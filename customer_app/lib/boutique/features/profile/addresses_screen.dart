import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/boutique_colors.dart';
import '../../providers/customer_provider.dart';
import '../../widgets/store_components.dart';

class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final customer = context.watch<CustomerProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('ناونیشانەکانم')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => editAddress(context),
        icon: const Icon(Icons.add),
        label: const Text('ناونیشانی نوێ'),
      ),
      body: customer.addresses.isEmpty
          ? const StoreEmpty(
              title: 'ناونیشانێک زیاد بکە',
              message: 'ناونیشانی پاشەکەوتکراو لە کاتی پارەدان بەکاربهێنە.',
              icon: Icons.location_on_outlined,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
              children: [
                for (final address in customer.addresses)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: StorePanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  address.label,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              if (customer.defaultAddress?.id == address.id)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: BoutiqueColors.goldWash,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Text(
                                    'سەرەکی',
                                    style: TextStyle(
                                      fontFamily: 'Vazirmatn',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: BoutiqueColors.dustyPink,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Text(address.address),
                          const SizedBox(height: 6),
                          Text(address.phone, textDirection: TextDirection.ltr),
                          Wrap(
                            spacing: 8,
                            children: [
                              TextButton.icon(
                                onPressed: () =>
                                    editAddress(context, address: address),
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('دەستکاری'),
                              ),
                              if (customer.defaultAddress?.id != address.id)
                                TextButton(
                                  onPressed: () =>
                                      customer.makeDefault(address.id),
                                  child: const Text('وەک سەرەکی'),
                                ),
                              TextButton(
                                onPressed: () {
                                  customer.removeAddress(address.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('ناونیشان سڕایەوە'),
                                      action: SnackBarAction(
                                        label: 'گەڕاندنەوە',
                                        onPressed: () =>
                                            customer.saveAddress(address),
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('سڕینەوە'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

Future<void> editAddress(
  BuildContext context, {
  CustomerAddress? address,
}) async {
  final provider = context.read<CustomerProvider>();
  final result = await Navigator.of(context).push<CustomerAddress>(
    MaterialPageRoute(builder: (_) => _AddressForm(address: address)),
  );
  if (result != null) provider.saveAddress(result);
}

class _AddressForm extends StatefulWidget {
  const _AddressForm({this.address});
  final CustomerAddress? address;
  @override
  State<_AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<_AddressForm> {
  final _form = GlobalKey<FormState>();
  late final _label = TextEditingController(
    text: widget.address?.label ?? 'ماڵ',
  );
  late final _address = TextEditingController(text: widget.address?.address);
  late final _phone = TextEditingController(text: widget.address?.phone);
  @override
  void dispose() {
    _label.dispose();
    _address.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.address == null ? 'ناونیشانی نوێ' : 'دەستکاری ناونیشان',
      ),
    ),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextFormField(
            controller: _label,
            decoration: const InputDecoration(labelText: 'ناوی ناونیشان'),
            validator: (v) => (v ?? '').trim().isEmpty ? 'ناو بنووسە' : null,
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _address,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'شار، گەڕەک، شەقام و ژمارەی ماڵ',
            ),
            validator: (v) =>
                (v ?? '').trim().length < 10 ? 'ناونیشانی تەواو بنووسە' : null,
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _phone,
            textDirection: TextDirection.ltr,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'ژمارەی مۆبایل'),
            validator: validatePhone,
          ),
          const SizedBox(height: 24),
          GoldButton(
            label: 'پاشەکەوتکردنی ناونیشان',
            icon: Icons.check_rounded,
            onPressed: () {
              if (!_form.currentState!.validate()) return;
              Navigator.pop(
                context,
                CustomerAddress(
                  id:
                      widget.address?.id ??
                      DateTime.now().microsecondsSinceEpoch.toString(),
                  label: _label.text.trim(),
                  address: _address.text.trim(),
                  phone: normalizePhone(_phone.text),
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}
