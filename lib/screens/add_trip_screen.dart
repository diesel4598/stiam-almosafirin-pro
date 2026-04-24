import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:water_tracker_mobile/theme/app_theme.dart';
import 'package:water_tracker_mobile/services/database_helper.dart';
import 'package:water_tracker_mobile/models/trip.dart';

class AddTripScreen extends StatefulWidget {
  final Trip? trip;
  const AddTripScreen({super.key, this.trip});

  @override
  State<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends State<AddTripScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _fromCity;
  String? _toCity;
  final _timeController = TextEditingController();
  final _busController = TextEditingController();
  final _passengersController = TextEditingController(text: '0');
  final _bottlesController = TextEditingController(text: '0');
  DateTime _selectedDate = DateTime.now();
  List<String> _cities = [
    'الدار البيضاء', 'الرباط', 'مراكش', 'فاس', 'طنجة', 'أكادير', 
    'مكناس', 'وجدة', 'القنيطرة', 'تطوان', 'آسفي', 'تمارة', 
    'سلا', 'بني ملال', 'الجديدة', 'الناظور', 'سطات', 'العرائش'
  ];

  @override
  void initState() {
    super.initState();
    _loadCities();
    if (widget.trip != null) {
      _fromCity = widget.trip!.fromCity;
      _toCity = widget.trip!.toCity;
      _timeController.text = widget.trip!.time;
      _busController.text = widget.trip!.busId;
      _passengersController.text = widget.trip!.passengersCount.toString();
      _bottlesController.text = widget.trip!.bottlesDistributed.toString();
      _selectedDate = DateFormat('yyyy-MM-dd').parse(widget.trip!.tripDate);
    }
  }

  @override
  void dispose() {
    _timeController.dispose();
    _busController.dispose();
    _passengersController.dispose();
    _bottlesController.dispose();
    super.dispose();
  }

  Future<void> _loadCities() async {
    final cities = await DatabaseHelper().getCities();
    setState(() {
      _cities = cities;
    });
  }

  Future<void> _addCityDialog() async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    
    return showDialog(
      context: context,
      builder: (context) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (focusNode.canRequestFocus) {
            focusNode.requestFocus();
          }
        });
        
        return AlertDialog(
          title: const Text('إضافة مدينة جديدة', textAlign: TextAlign.right),
          content: TextField(
            key: const ValueKey('new_city_name_field'),
            controller: controller,
            focusNode: focusNode,
            textAlign: TextAlign.right,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(hintText: 'اسم المدينة'),
          ),
        actions: [
          TextButton(
            key: const ValueKey('cancel_add_city'),
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            key: const ValueKey('confirm_add_city'),
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await DatabaseHelper().insertCity(controller.text);
                await _loadCities();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تمت إضافة ${controller.text} بنجاح')),
                  );
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('إضافة'),
          ),
          ],
        );
      },
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTrip() async {
    if (_fromCity != null && _toCity != null && _fromCity == _toCity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن أن تكون مدينة الانطلاق والوصول هي نفسها')),
      );
      return;
    }

    if (_formKey.currentState!.validate() && _fromCity != null && _toCity != null) {
      final bottles = int.tryParse(_bottlesController.text) ?? 0;
      
      final trip = Trip(
        id: widget.trip?.id,
        fromCity: _fromCity!,
        toCity: _toCity!,
        time: _timeController.text,
        tripDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
        busId: _busController.text,
        status: 'في الطريق',
        passengersCount: int.tryParse(_passengersController.text) ?? 0,
        bottlesDistributed: bottles,
      );

      if (widget.trip == null) {
        await DatabaseHelper().insertTrip(trip);
        await DatabaseHelper().deductInventory(bottles);
      } else {
        await DatabaseHelper().updateTrip(trip);
        await DatabaseHelper().adjustInventory(widget.trip!.bottlesDistributed, bottles);
      }
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.trip == null ? 'إضافة رحلة جديدة' : 'تعديل الرحلة'),
        leading: IconButton(
          key: const ValueKey('back_button'),
          icon: const Icon(LucideIcons.arrowRight),
          onPressed: () => Navigator.pop(context),
          tooltip: 'العودة',
        ),
        actions: [
          IconButton(
            key: const ValueKey('refresh_cities_button'),
            onPressed: _loadCities,
            icon: const Icon(LucideIcons.refreshCw),
            tooltip: 'تحديث المدن',
          ),
          IconButton(
            key: const ValueKey('add_city_button'),
            onPressed: _addCityDialog,
            icon: const Icon(LucideIcons.circlePlus),
            tooltip: 'إضافة مدينة',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDropdownField(
                key: const ValueKey('from_city_dropdown'),
                value: _fromCity,
                label: 'من مدينة',
                items: _cities,
                icon: LucideIcons.mapPin,
                onChanged: (val) => setState(() => _fromCity = val),
              ),
              const SizedBox(height: 16),
              _buildDropdownField(
                key: const ValueKey('to_city_dropdown'),
                value: _toCity,
                label: 'إلى مدينة',
                items: _cities,
                icon: LucideIcons.navigation,
                onChanged: (val) => setState(() => _toCity = val),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.calendar, size: 20, color: AppTheme.primaryColor),
                      const SizedBox(width: 12),
                      const Text('تاريخ الرحلة', style: TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text(
                        DateFormat('yyyy-MM-dd').format(_selectedDate),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildInputField(
                key: const ValueKey('time_input'),
                controller: _timeController,
                label: 'وقت الانطلاق',
                icon: LucideIcons.clock,
                hint: 'اختر وقت الانطلاق',
                readOnly: true,
                onTap: () async {
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _timeController.text = picked.format(context);
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              _buildInputField(
                key: const ValueKey('bus_id_input'),
                controller: _busController,
                label: 'رقم الشاحنة / الحافلة',
                icon: LucideIcons.bus,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                key: const ValueKey('passengers_count_input'),
                controller: _passengersController,
                label: 'عدد المسافرين',
                icon: LucideIcons.users,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                key: const ValueKey('bottles_distributed_input'),
                controller: _bottlesController,
                label: 'عدد القنينات الموزعة',
                icon: LucideIcons.droplets,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                key: const ValueKey('save_trip_button'),
                onPressed: _saveTrip,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'حفظ الرحلة',
                  style: GoogleFonts.publicSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    Key? key,
    required String? value,
    required String label,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    // Ensure value exists in items to avoid crash
    final safeValue = items.contains(value) ? value : null;
    
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: DropdownButtonFormField<String>(
        key: key,
        initialValue: safeValue,
        isExpanded: true,
        items: items.map((city) => DropdownMenuItem(
          value: city,
          alignment: AlignmentDirectional.centerEnd,
          child: Text(city, textAlign: TextAlign.right),
        )).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: true,
          prefixIcon: Icon(icon, size: 20, color: AppTheme.primaryColor),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        validator: (value) => value == null ? 'يرجى اختيار مدينة' : null,
      ),
    );
  }

  Widget _buildInputField({
    Key? key,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    bool autofocus = false,
  }) {
    return TextFormField(
      key: key,
      controller: controller,
      textAlign: TextAlign.right,
      readOnly: readOnly,
      onTap: onTap,
      autofocus: autofocus,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: AppTheme.primaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) => (value == null || value.isEmpty) ? 'هذا الحقل مطلوب' : null,
    );
  }
}
