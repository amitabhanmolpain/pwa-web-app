// bus_schedule_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_notifier.dart';

class BusScheduleScreen extends StatefulWidget {
  const BusScheduleScreen({super.key});

  @override
  State<BusScheduleScreen> createState() => _BusScheduleScreenState();
}

class _BusScheduleScreenState extends State<BusScheduleScreen>
    with SingleTickerProviderStateMixin {
  int _selectedView = 0; // 0: Day, 1: Week, 2: Month
  int _selectedRouteType = 0; // 0: City to City, 1: City to Village, 2: Intercity
  bool _isLoading = true;
  String _errorMessage = '';

  // Animation
  late AnimationController _animationController;

  List<Map<String, dynamic>> _cityToCityRoutes = [];
  List<Map<String, dynamic>> _cityToVillageRoutes = [];
  List<Map<String, dynamic>> _intercityRoutes = [];

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
          ..repeat(reverse: true);
    _fetchScheduleData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchScheduleData() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _cityToCityRoutes = [
        {'time': '05:00', 'name': 'Downtown Express', 'destination': 'Business District', 'status': 'Active'},
        {'time': '05:30', 'name': 'Metro Line 1', 'destination': 'Shopping Mall', 'status': 'Active'},
        {'time': '06:00', 'name': 'Central Loop', 'destination': 'Train Station', 'status': 'Scheduled'},
        {'time': '06:30', 'name': 'University Route', 'destination': 'Campus East', 'status': 'Scheduled'},
        {'time': '07:00', 'name': 'Hospital Line', 'destination': 'Medical Center', 'status': 'Scheduled'},
      ];
      _isLoading = false;
    });
  }

  void _refreshData() {
    _fetchScheduleData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bus Schedule"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // View Selection with Icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildViewOption(Icons.calendar_today, "Day View", 0),
                      _buildViewOption(Icons.view_week, "Week View", 1),
                      _buildViewOption(Icons.calendar_month, "Month View", 2),
                    ],
                  ),

                  const Divider(height: 32),

                  // Route Type with Icons
                  Text("Route Type", style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildRouteTypeOption(Icons.location_city, "City to City", 0),
                      _buildRouteTypeOption(Icons.park, "City to Village", 1),
                      _buildRouteTypeOption(Icons.directions_bus, "Intercity", 2),
                    ],
                  ),

                  const Divider(height: 32),

                  // Schedule List
                  Text("Schedule for Today", style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _buildScheduleList(),
                ],
              ),
            ),
    );
  }

  Widget _buildViewOption(IconData icon, String title, int index) {
    final isSelected = _selectedView == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedView = index);
        _refreshData();
      },
      child: Column(
        children: [
          Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
          const SizedBox(height: 4),
          Text(title,
              style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.blue : Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildRouteTypeOption(IconData icon, String title, int index) {
    final isSelected = _selectedRouteType == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedRouteType = index);
        _refreshData();
      },
      child: Column(
        children: [
          Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
          const SizedBox(height: 4),
          Text(title,
              style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.blue : Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildScheduleList() {
    final routes = _cityToCityRoutes;
    return Column(
      children: routes.map((route) {
        return Card(
          child: ListTile(
            leading: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(route['time'], style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            title: Text(route['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("To: ${route['destination']}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on, color: Colors.blue.shade400),
                const SizedBox(width: 8),
                const Icon(Icons.more_vert),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}