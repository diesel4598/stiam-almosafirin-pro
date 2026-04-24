import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:water_tracker_mobile/theme/app_theme.dart';
import 'package:water_tracker_mobile/services/database_helper.dart';
import 'package:water_tracker_mobile/services/report_service.dart';
import 'package:water_tracker_mobile/models/inventory_item.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<InventoryItem> _items = [];
  bool _isLoading = true;
  int _totalDistributed = 0;

  @override
  void initState() {
    super.initState();
    _refreshInventory();
  }

  Future<void> _refreshInventory() async {
    setState(() => _isLoading = true);
    final items = await DatabaseHelper().getInventory();
    final stats = await DatabaseHelper().getReportStats();
    setState(() {
      _items = items;
      _totalDistributed = stats['totalDistributed'] ?? 0;
      _isLoading = false;
    });
  }

  Future<void> _zeroInventory(int id) async {
    await DatabaseHelper().zeroInventory(id);
    _refreshInventory();
  }

  Future<void> _deleteInventory(int id) async {
    await DatabaseHelper().deleteInventory(id);
    _refreshInventory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'إدارة المخزون',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        actions: [
          IconButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('تأكيد الحذف الكلي', textAlign: TextAlign.right),
                  content: const Text('هل أنت متأكد من حذف جميع بيانات المخزون؟ لا يمكن التراجع عن هذا الإجراء.', textAlign: TextAlign.right),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف الكل', style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (confirm == true) {
                await DatabaseHelper().deleteAllInventory();
                _refreshInventory();
              }
            },
            icon: const Icon(LucideIcons.trash2, color: Colors.red),
            tooltip: 'حذف جميع المخزون',
          ),
          IconButton(
            onPressed: () async {
              if (_items.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('المخزون فارغ حالياً')),
                );
                return;
              }
              await ReportService.generateInventoryReport(
                items: _items.map((e) => e.toMap()).toList(),
              );
            },
            icon: const Icon(LucideIcons.printer),
            tooltip: 'طباعة كشف المخزون',
          ),
          IconButton(
            onPressed: () => _showInventoryDialog(),
            icon: const Icon(LucideIcons.circlePlus),
            tooltip: 'إضافة مخزون',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildStatsHeader(_items),
                Expanded(
                  child: _items.isEmpty
                      ? const Center(child: Text('المخزون فارغ حالياً'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            return _buildInventoryItem(_items[index], index);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsHeader(List<InventoryItem> items) {
    int totalItems = items.length;
    int totalBottlesInStock = items.fold(0, (sum, item) => sum + item.quantity);
    int remainingBottles = totalBottlesInStock;
    double totalLitres = remainingBottles * 5.0; // Assuming 5L per bottle as per seed data

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSimpleStat('$totalItems', 'أصناف'),
              _buildSimpleDivider(),
              _buildSimpleStat('$remainingBottles', 'قنينة متبقية'),
              _buildSimpleDivider(),
              _buildSimpleStat(totalLitres.toStringAsFixed(1), 'لتر متاح'),
            ],
          ),
        ],
      ),
    ).animate().slideY(begin: -0.2);
  }

  Widget _buildSimpleStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
      ],
    );
  }

  Widget _buildSimpleDivider() {
    return Container(height: 30, width: 1, color: Colors.white.withValues(alpha: 0.2));
  }

  Future<void> _showInventoryDialog([InventoryItem? item]) async {
    final nameController = TextEditingController(text: item?.name);
    final quantityController = TextEditingController(text: item?.quantity.toString() ?? '0');
    final locationController = TextEditingController(text: item?.location ?? 'المستودع الرئيسي');
    final unitController = TextEditingController(text: item?.unit ?? 'لتر');
    final receiptNumberController = TextEditingController(text: item?.receiptNumber);
    final receiptDateTimeController = TextEditingController(text: item?.receiptDateTime ?? DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()));

    final focusNode = FocusNode();
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        // Force focus after the dialog is built and animation starts
        Future.delayed(const Duration(milliseconds: 300), () {
          if (focusNode.canRequestFocus) {
            focusNode.requestFocus();
          }
        });

        return AlertDialog(
          scrollable: true,
          title: Text(
            item == null ? 'إضافة مخزون' : 'تعديل مخزون',
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
                  labelText: 'اسم الصنف',
                  hintText: 'مثلاً: مياه معدنية 90CL',
                  border: OutlineInputBorder(),
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: receiptNumberController,
              textAlign: TextAlign.right,
              scrollPadding: const EdgeInsets.all(100),
              decoration: const InputDecoration(
                labelText: 'رقم وصل الاستلام',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: receiptDateTimeController,
              textAlign: TextAlign.right,
              scrollPadding: const EdgeInsets.all(100),
              readOnly: true,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                  if (date != null) {
                    if (!context.mounted) return;
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null && context.mounted) {
                      final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                      receiptDateTimeController.text = DateFormat('yyyy-MM-dd HH:mm').format(dt);
                    }
                  }
              },
              decoration: const InputDecoration(
                labelText: 'تاريخ ووقت الاستلام',
                prefixIcon: Icon(LucideIcons.calendar),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              textAlign: TextAlign.right,
              keyboardType: TextInputType.number,
              scrollPadding: const EdgeInsets.all(100),
              decoration: const InputDecoration(
                labelText: 'الكمية',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: unitController,
              textAlign: TextAlign.right,
              scrollPadding: const EdgeInsets.all(100),
              decoration: const InputDecoration(
                labelText: 'الوحدة (لتر، قنينة، الخ)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: locationController,
              textAlign: TextAlign.right,
              scrollPadding: const EdgeInsets.all(100),
              decoration: const InputDecoration(
                labelText: 'الموقع',
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
                  if (item != null)
                    TextButton(
                      onPressed: () async {
                        await DatabaseHelper().deleteInventory(item.id!);
                        await _refreshInventory();
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text('حذف', style: TextStyle(color: Colors.red)),
                    ),
                  ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isEmpty) return;
                      final newItem = InventoryItem(
                        id: item?.id,
                        name: nameController.text,
                        quantity: int.tryParse(quantityController.text) ?? 0,
                        location: locationController.text,
                        unit: unitController.text,
                        receiptNumber: receiptNumberController.text,
                        receiptDateTime: receiptDateTimeController.text,
                      );
                      if (item == null) {
                        await DatabaseHelper().insertInventory(newItem);
                      } else {
                        await DatabaseHelper().updateInventory(newItem);
                      }
                      await _refreshInventory();
                      if (context.mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(item == null ? 'إضافة' : 'حفظ'),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
    },
  );
  }

  Widget _buildInventoryItem(InventoryItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.package, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  textAlign: TextAlign.right,
                ),
                Text(
                  'الموقع: ${item.location}',
                  style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6)),
                  textAlign: TextAlign.right,
                ),
                if (item.receiptNumber != null && item.receiptNumber!.isNotEmpty)
                  Text(
                    'وصل: ${item.receiptNumber}',
                    style: const TextStyle(fontSize: 11),
                    textAlign: TextAlign.right,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.quantity}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryColor),
              ),
              Text(
                item.unit,
                style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              IconButton(
                onPressed: () => _showInventoryDialog(item),
                icon: const Icon(LucideIcons.pencil, size: 20, color: Colors.blueAccent),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(height: 8),
              IconButton(
                onPressed: () => _zeroInventory(item.id!),
                icon: const Icon(LucideIcons.rotateCcw, size: 20, color: Colors.orangeAccent),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(height: 8),
              IconButton(
                onPressed: () => _deleteInventory(item.id!),
                icon: const Icon(LucideIcons.trash2, size: 20, color: Colors.redAccent),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1);
  }
}
