import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:water_tracker_mobile/theme/app_theme.dart';
import 'package:water_tracker_mobile/services/database_helper.dart';
import 'package:water_tracker_mobile/models/trip.dart';
import 'package:water_tracker_mobile/screens/add_trip_screen.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  late Future<List<Trip>> _tripsFuture;

  @override
  void initState() {
    super.initState();
    _tripsFuture = DatabaseHelper().getTrips();
  }

  void _refreshTrips() {
    setState(() {
      _tripsFuture = DatabaseHelper().getTrips();
    });
  }

  Future<void> _deleteTrip(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف', textAlign: TextAlign.right),
        content: const Text('هل أنت متأكد من حذف هذه الرحلة؟', textAlign: TextAlign.right),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper().deleteTrip(id);
      _refreshTrips();
    }
  }

  Future<void> _editTrip(Trip trip) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddTripScreen(trip: trip)),
    );
    if (result == true) {
      _refreshTrips();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'رحلات اليوم',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        actions: [
          IconButton(
            onPressed: _refreshTrips,
            icon: const Icon(LucideIcons.refreshCw),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(LucideIcons.search),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: const ValueKey('add_trip_fab'),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTripScreen()),
          );
          if (result == true) {
            _refreshTrips();
          }
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ).animate().scale(delay: 500.ms),
      body: FutureBuilder<List<Trip>>(
        future: _tripsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا توجد رحلات اليوم'));
          }
          
          final trips = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: trips.length,
            itemBuilder: (context, index) {
              return _buildTripCard(trips[index], index)
                  .animate()
                  .fadeIn(delay: (index * 100).ms)
                  .slideX(begin: 0.1);
            },
          );
        },
      ),
    );
  }

  Widget _buildTripCard(Trip trip, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCityInfo(trip.fromCity, 'من'),
                Icon(LucideIcons.arrowLeft, color: AppTheme.primaryColor),
                _buildCityInfo(trip.toCity, 'إلى'),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetadata(LucideIcons.clock, trip.time),
                _buildMetadata(LucideIcons.bus, trip.busId),
                _buildStatusChip(trip.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildMetadata(LucideIcons.users, '${trip.passengersCount} مسافر'),
                    const SizedBox(width: 8),
                    _buildMetadata(LucideIcons.droplets, '${trip.bottlesDistributed} قنينة'),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _deleteTrip(trip.id!),
                      icon: const Icon(LucideIcons.trash2, size: 20, color: Colors.redAccent),
                      tooltip: 'حذف',
                    ),
                    IconButton(
                      onPressed: () => _editTrip(trip),
                      icon: const Icon(LucideIcons.pencil, size: 20, color: Colors.blueAccent),
                      tooltip: 'تعديل',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCityInfo(String city, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
        ),
        Text(
          city,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildMetadata(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    bool isActive = status == 'في الطريق';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          color: isActive ? AppTheme.primaryColor : Colors.green,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
