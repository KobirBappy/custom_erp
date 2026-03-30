import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../businesses/providers/business_provider.dart';
import '../models/contact.dart';
import '../providers/contact_provider.dart';

class ContactFormScreen extends ConsumerStatefulWidget {
  const ContactFormScreen({super.key, this.contactId});
  final String? contactId;

  @override
  ConsumerState<ContactFormScreen> createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends ConsumerState<ContactFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _taxCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController(text: '0');
  ContactType _type = ContactType.customer;
  int _payTermDays = 0;
  bool _loading = false;

  Contact? _existing;

  @override
  void initState() {
    super.initState();
    if (widget.contactId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final contacts = ref.read(contactsProvider);
        try {
          _existing = contacts.firstWhere((c) => c.id == widget.contactId);
          _nameCtrl.text = _existing!.name;
          _phoneCtrl.text = _existing!.phone;
          _emailCtrl.text = _existing!.email;
          _addressCtrl.text = _existing!.address;
          _cityCtrl.text = _existing!.city;
          _taxCtrl.text = _existing!.taxNumber;
          _balanceCtrl.text = _existing!.openingBalance.toString();
          setState(() {
            _type = _existing!.type;
            _payTermDays = _existing!.payTermDays;
          });
        } catch (_) {}
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _taxCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final notifier = ref.read(contactsProvider.notifier);
    final currentBusiness = ref.read(currentBusinessProvider);
    final contact = Contact(
      id: _existing?.id ?? '',
      businessId: _existing?.businessId ?? currentBusiness?.id ?? '',
      name: _nameCtrl.text.trim(),
      type: _type,
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      taxNumber: _taxCtrl.text.trim(),
      openingBalance: double.tryParse(_balanceCtrl.text) ?? 0,
      payTermDays: _payTermDays,
    );

    if (_existing != null) {
      await notifier.update(contact);
    } else {
      await notifier.add(contact);
    }

    if (mounted) {
      context.go('/contacts');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(_existing != null ? 'Contact updated' : 'Contact added')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Contact' : 'Add Contact'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/contacts'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Contact Type',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      SegmentedButton<ContactType>(
                        segments: const [
                          ButtonSegment(
                              value: ContactType.customer,
                              label: Text('Customer')),
                          ButtonSegment(
                              value: ContactType.supplier,
                              label: Text('Supplier')),
                          ButtonSegment(
                              value: ContactType.both, label: Text('Both')),
                        ],
                        selected: {_type},
                        onSelectionChanged: (s) =>
                            setState(() => _type = s.first),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Contact Name *'),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(
                          child: TextFormField(
                            controller: _phoneCtrl,
                            decoration:
                                const InputDecoration(labelText: 'Phone'),
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _emailCtrl,
                            decoration:
                                const InputDecoration(labelText: 'Email'),
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressCtrl,
                        decoration: const InputDecoration(labelText: 'Address'),
                      ),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cityCtrl,
                            decoration:
                                const InputDecoration(labelText: 'City'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _taxCtrl,
                            decoration:
                                const InputDecoration(labelText: 'Tax Number'),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(
                          child: TextFormField(
                            controller: _balanceCtrl,
                            decoration: const InputDecoration(
                                labelText: 'Opening Balance'),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _payTermDays,
                            decoration: const InputDecoration(
                                labelText: 'Pay Term (days)'),
                            items: [0, 7, 14, 30, 45, 60, 90]
                                .map((d) => DropdownMenuItem(
                                    value: d,
                                    child:
                                        Text(d == 0 ? 'No term' : '$d days')))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _payTermDays = v ?? 0),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(isEdit ? 'Update Contact' : 'Save Contact'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
