import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/enums.dart';
import '../../services/auth_provider.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _businessNameController;
  late final TextEditingController _cityController;

  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthProvider>().currentProfile;
    _fullNameController = TextEditingController(text: profile?.fullName ?? '');
    _phoneController = TextEditingController(text: profile?.phone ?? '');
    _businessNameController =
        TextEditingController(text: profile?.businessName ?? '');
    _cityController = TextEditingController(text: profile?.city ?? '');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _businessNameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _enterEditMode() => setState(() => _editing = true);

  void _cancelEdit() {
    final profile = context.read<AuthProvider>().currentProfile;
    _fullNameController.text = profile?.fullName ?? '';
    _phoneController.text = profile?.phone ?? '';
    _businessNameController.text = profile?.businessName ?? '';
    _cityController.text = profile?.city ?? '';
    setState(() => _editing = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final t = AppLocalizations.of(context)!;
    setState(() => _saving = true);
    try {
      await context.read<AuthProvider>().updateProfile(
            fullName: _fullNameController.text.trim(),
            phone: _phoneController.text.trim(),
            businessName: _businessNameController.text.trim(),
            city: _cityController.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.profileUpdated)),
      );
      setState(() => _editing = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.profileUpdateFailed),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _accountTypeLabel(AccountType type, AppLocalizations t) {
    switch (type) {
      case AccountType.customer:
        return t.customer;
      case AccountType.individualOwner:
        return t.individualOwner;
      case AccountType.dealership:
        return t.dealership;
      case AccountType.admin:
        return 'Admin';
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final profile = auth.currentProfile;
    final theme = Theme.of(context);

   if (profile == null) {
  return Scaffold(
    appBar: AppBar(title: Text(t.profile)),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text('Loading profile...'),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              context.read<AuthProvider>().retryLoadProfile();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}

    final isDealership = profile.accountType == AccountType.dealership;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.profile),
        actions: [
          if (!_editing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: t.editProfile,
              onPressed: _enterEditMode,
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: t.settings,
              onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.1),
                    child: Text(
                      profile.fullName.isNotEmpty
                          ? profile.fullName[0].toUpperCase()
                          : '?',
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_accountTypeLabel(profile.accountType, t),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            )),
                        if (isDealership && profile.verified) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.verified,
                              size: 16, color: theme.colorScheme.primary),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _fullNameController,
                  enabled: _editing && !_saving,
                  decoration: InputDecoration(
                    labelText: t.fullName,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return t.fullNameRequired;
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: profile.email,
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: t.email,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  enabled: _editing && !_saving,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: t.phone,
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                ),
                if (isDealership) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _businessNameController,
                    enabled: _editing && !_saving,
                    decoration: InputDecoration(
                      labelText: t.businessName,
                      prefixIcon: const Icon(Icons.business_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cityController,
                    enabled: _editing && !_saving,
                    decoration: InputDecoration(
                      labelText: t.city,
                      prefixIcon: const Icon(Icons.location_city_outlined),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                if (_editing) ...[
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(t.saveChanges),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _saving ? null : _cancelEdit,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(t.cancel),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
