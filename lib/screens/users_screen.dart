import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:water_tracker_mobile/theme/app_theme.dart';
import 'package:water_tracker_mobile/services/database_helper.dart';
import 'package:water_tracker_mobile/models/user.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<User> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final users = await DatabaseHelper().getUsers();
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  Future<void> _showUserDialog([User? user]) async {
    final nameController = TextEditingController(text: user?.name);
    final emailController = TextEditingController(text: user?.email);
    final passwordController = TextEditingController(text: user?.password ?? '123456');
    String role = user?.role ?? 'سائق';

    final focusNode = FocusNode();

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        // Delayed focus request to accommodate dialog animation
        Future.delayed(const Duration(milliseconds: 300), () {
          if (focusNode.canRequestFocus) {
            focusNode.requestFocus();
          }
        });

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              scrollable: true,
              title: Text(
                user == null ? 'إضافة مستخدم' : 'تعديل مستخدم',
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameController,
                    focusNode: focusNode,
                    textAlign: TextAlign.right,
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    scrollPadding: const EdgeInsets.all(100),
                    decoration: const InputDecoration(
                      labelText: 'الاسم الكامل',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    textAlign: TextAlign.right,
                    scrollPadding: const EdgeInsets.all(100),
                    decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    textAlign: TextAlign.right,
                    scrollPadding: const EdgeInsets.all(100),
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'كلمة المرور',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: role,
                    alignment: AlignmentDirectional.centerEnd,
                    items: ['مدير', 'سائق', 'محاسب']
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (val) => setDialogState(() => role = val!),
                    decoration: const InputDecoration(
                      labelText: 'الدور',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إلغاء'),
                    ),
                    Row(
                      children: [
                        if (user != null)
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _deleteUser(user.id!);
                            },
                            child: const Text('حذف', style: TextStyle(color: Colors.red)),
                          ),
                        ElevatedButton(
                          onPressed: () async {
                            if (nameController.text.isEmpty) return;
                            final newUser = User(
                              id: user?.id,
                              name: nameController.text,
                              email: emailController.text,
                              role: role,
                              password: passwordController.text,
                            );
                            if (user == null) {
                              await DatabaseHelper().insertUser(newUser);
                            } else {
                              await DatabaseHelper().updateUser(newUser);
                            }
                            await _loadUsers();
                            if (context.mounted) Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(user == null ? 'إضافة' : 'حفظ'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteUser(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف', textAlign: TextAlign.right),
        content: const Text('هل أنت متأكد من حذف هذا المستخدم؟', textAlign: TextAlign.right),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await DatabaseHelper().deleteUser(id);
      if (context.mounted) {
        await _loadUsers();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المستخدمين'),
        actions: [
          IconButton(
            onPressed: () => _showUserDialog(),
            icon: const Icon(LucideIcons.userPlus),
            tooltip: 'إضافة مستخدم',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const Center(child: Text('لا يوجد مستخدمون حالياً'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    return _buildUserTile(_users[index]);
                  },
                ),
    );
  }

  Widget _buildUserTile(User user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
            child: Text(
              user.name.isNotEmpty ? user.name[0] : '?',
              style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          // User Info on the right (Start in RTL)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                user.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.right,
              ),
              Text(
                user.role,
                style: TextStyle(
                  fontSize: 12, 
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6)
                ),
                textAlign: TextAlign.right,
              ),
            ],
          ),
          const Spacer(),
          // Buttons on the left (End in RTL)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _deleteUser(user.id!),
                icon: const Icon(LucideIcons.trash2, size: 20, color: Colors.redAccent),
                tooltip: 'حذف',
              ),
              IconButton(
                onPressed: () => _showUserDialog(user),
                icon: const Icon(LucideIcons.pencil, size: 20, color: Colors.blueAccent),
                tooltip: 'تعديل',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
