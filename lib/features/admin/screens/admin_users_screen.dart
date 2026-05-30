import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/enums.dart';
import '../../../models/models.dart';
import '../../../theme/app_colors.dart';
import '../providers/admin_provider.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: admin.loadAll,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search + filter bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search by name or email...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              admin.filterUsers(search: '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (v) => admin.filterUsers(search: v),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: admin.users.length ==
                            admin.filteredUsers.length,
                        onTap: admin.clearUserTypeFilter,
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Customers',
                        selected: false,
                        onTap: () => admin.filterUsers(
                            type: AccountType.customer),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Individual Owners',
                        selected: false,
                        onTap: () => admin.filterUsers(
                            type: AccountType.individualOwner),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Dealerships',
                        selected: false,
                        onTap: () => admin.filterUsers(
                            type: AccountType.dealership),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Count
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${admin.filteredUsers.length} user(s)',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ),
          ),

          // List
          Expanded(
            child: admin.loading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.navy))
                : admin.filteredUsers.isEmpty
                    ? const Center(child: Text('No users found.'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: admin.filteredUsers.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final user = admin.filteredUsers[i];
                          return _UserTile(
                            user: user,
                            onDelete: () =>
                                _confirmDelete(context, admin, user),
                            onVerify: user.isDealership && !user.verified
                                ? () => _confirmVerify(
                                    context, admin, user)
                                : null,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, AdminProvider admin, Profile user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
            'Are you sure you want to delete "${user.fullName}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await admin.deleteUser(user.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('${user.fullName} deleted'),
                      backgroundColor: Colors.red[700]),
                );
              }
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmVerify(
      BuildContext context, AdminProvider admin, Profile user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Verify Dealership'),
        content: Text(
            'Mark "${user.businessName ?? user.fullName}" as a verified dealership?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await admin.verifyDealership(user.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Dealership verified ✓'),
                      backgroundColor: Color(0xFF2E7D32)),
                );
              }
            },
            child: const Text('Verify',
                style: TextStyle(color: Color(0xFF2E7D32))),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final Profile user;
  final VoidCallback onDelete;
  final VoidCallback? onVerify;

  const _UserTile({
    required this.user,
    required this.onDelete,
    this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    final typeColor = user.isCustomer
        ? AppColors.navy
        : user.isIndividualOwner
            ? const Color(0xFF1976D2)
            : const Color(0xFF2E7D32);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: typeColor.withOpacity(0.12),
            backgroundImage: user.avatarUrl != null
                ? NetworkImage(user.avatarUrl!)
                : null,
            child: user.avatarUrl == null
                ? Text(
                    user.fullName.isNotEmpty
                        ? user.fullName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                        color: typeColor, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.fullName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (user.isDealership && user.verified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified,
                          color: Color(0xFF2E7D32), size: 14),
                    ],
                  ],
                ),
                Text(user.email,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _typeLabel(user.accountType),
                    style: TextStyle(
                        fontSize: 11,
                        color: typeColor,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              if (onVerify != null)
                IconButton(
                  icon: const Icon(Icons.verified_outlined,
                      color: Color(0xFF2E7D32)),
                  tooltip: 'Verify dealership',
                  onPressed: onVerify,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Delete user',
                onPressed: onDelete,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _typeLabel(AccountType type) {
  switch (type) {
    case AccountType.customer:
      return 'Customer';
    case AccountType.individualOwner:
      return 'Individual Owner';
    case AccountType.dealership:
      return 'Dealership';
    case AccountType.admin:
      return 'Admin';
  }
}
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: selected ? Colors.white : Colors.grey[700],
            fontWeight:
                selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
