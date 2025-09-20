import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> with SingleTickerProviderStateMixin {
  String _selectedFilter = 'All Trips';
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // API endpoints
  static const String BASE_URL = 'http://your-spring-boot-server:8080/api';
  static const String TRIPS_ENDPOINT = '$BASE_URL/trips';
  static const String MONTHLY_STATS_ENDPOINT = '$BASE_URL/trips/stats/monthly';
  static const String TRIP_DETAILS_ENDPOINT = '$BASE_URL/trips';

  // Trip data
  List<Trip> _trips = [];
  MonthlyStats _monthlyStats = MonthlyStats();

  final List<Map<String, dynamic>> _filters = [
    {'label': 'All Trips', 'value': 'all'},
    {'label': 'Today', 'value': 'today'},
    {'label': 'This Week', 'value': 'week'},
    {'label': 'This Month', 'value': 'month'}
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Start animation
    _animationController.forward();
    
    // Call API to fetch initial trip data
    _fetchTripData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // API call to fetch trip data
  Future<void> _fetchTripData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      
      if (accessToken == null) {
        throw Exception('Not authenticated. Please login again.');
      }

      // Fetch monthly stats
      final statsResponse = await http.get(
        Uri.parse(MONTHLY_STATS_ENDPOINT),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (statsResponse.statusCode == 200) {
        final statsData = json.decode(statsResponse.body);
        setState(() {
          _monthlyStats = MonthlyStats.fromJson(statsData);
        });
      } else if (statsResponse.statusCode == 401) {
        final newToken = await _refreshToken();
        if (newToken != null) {
          await _fetchTripData();
          return;
        }
      }

      // Fetch trips with filter
      final filterParam = _filters.firstWhere(
        (f) => f['label'] == _selectedFilter,
        orElse: () => _filters[0],
      )['value'];

      final tripsResponse = await http.get(
        Uri.parse('$TRIPS_ENDPOINT?filter=$filterParam'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (tripsResponse.statusCode == 200) {
        final tripsData = json.decode(tripsResponse.body);
        setState(() {
          _trips = (tripsData['trips'] as List)
              .map((trip) => Trip.fromJson(trip))
              .toList();
          _isLoading = false;
        });
      } else if (tripsResponse.statusCode == 401) {
        final newToken = await _refreshToken();
        if (newToken != null) {
          await _fetchTripData();
          return;
        }
      } else {
        throw Exception('Failed to load trips: ${tripsResponse.statusCode}');
      }

    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading trips: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // API call for viewing trip details
  Future<void> _viewTripDetails(String tripId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      
      final response = await http.get(
        Uri.parse('$TRIP_DETAILS_ENDPOINT/$tripId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final tripDetails = json.decode(response.body);
        // Show trip details dialog or navigate to details screen
        _showTripDetailsDialog(tripDetails);
      } else if (response.statusCode == 401) {
        final newToken = await _refreshToken();
        if (newToken != null) {
          await _viewTripDetails(tripId);
          return;
        }
      } else {
        throw Exception('Failed to load trip details');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading trip details: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showTripDetailsDialog(Map<String, dynamic> tripDetails) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Trip Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Route: ${tripDetails['route'] ?? 'N/A'}'),
                Text('Date: ${tripDetails['date'] ?? 'N/A'}'),
                Text('Distance: ${tripDetails['distance'] ?? 'N/A'}'),
                Text('Duration: ${tripDetails['duration'] ?? 'N/A'}'),
                Text('Status: ${tripDetails['status'] ?? 'N/A'}'),
                Text('Vehicle: ${tripDetails['vehicle'] ?? 'N/A'}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Refresh JWT token
  Future<String?> _refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      
      if (refreshToken == null) return null;

      final response = await http.post(
        Uri.parse('$BASE_URL/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $refreshToken',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final newAccessToken = responseData['accessToken'];
        await prefs.setString('access_token', newAccessToken);
        return newAccessToken;
      }
    } catch (e) {
      print('Token refresh failed: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip History'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(15),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Monthly Overview Section with animation
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(-1, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _animationController,
                        curve: Curves.easeOut,
                      )),
                      child: const Text(
                        'Monthly Overview',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Animated Stats Cards (Removed Passengers and Revenue)
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.2,
                      children: [
                        _buildAnimatedStatCard(0, _monthlyStats.totalTrips.toString(), 'Total Trips', Icons.directions_bus_filled, Colors.blue),
                        _buildAnimatedStatCard(1, _monthlyStats.totalDistance, 'Distance', Icons.navigation_rounded, Colors.green),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Filter Chips with icons and counts
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, -0.5),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _animationController,
                        curve: Curves.easeOut,
                      )),
                      child: SizedBox(
                        height: 50,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: _filters.asMap().entries.map((entry) {
                            final index = entry.key;
                            final filter = entry.value;
                            final isSelected = _selectedFilter == filter['label'];
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: FilterChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(_getFilterIcon(filter['label']), size: 16),
                                    const SizedBox(width: 4),
                                    Text(filter['label']),
                                  ],
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedFilter = filter['label'];
                                  });
                                  _fetchTripData();
                                },
                                backgroundColor: Colors.white,
                                selectedColor: const Color(0xFF6366F1),
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: isSelected
                                        ? const Color(0xFF6366F1)
                                        : Colors.grey[300]!,
                                    width: isSelected ? 0 : 1,
                                  ),
                                ),
                                showCheckmark: false,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Animated Trip List
                    ScaleTransition(
                      scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: Curves.easeOut,
                        ),
                      ),
                      child: _buildTripList(),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  IconData _getFilterIcon(String filterLabel) {
    switch (filterLabel) {
      case 'All Trips':
        return Icons.all_inclusive;
      case 'Today':
        return Icons.today;
      case 'This Week':
        return Icons.calendar_view_week;
      case 'This Month':
        return Icons.calendar_today;
      default:
        return Icons.all_inclusive;
    }
  }

  Widget _buildAnimatedStatCard(int index, String value, String title, IconData icon, Color color) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(0.1 + index * 0.1, 1.0, curve: Curves.easeOut),
        ),
      ),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(0.1 + index * 0.1, 1.0, curve: Curves.easeIn),
          ),
        ),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTripList() {
    if (_trips.isEmpty) {
      return const Center(
        child: Text(
          'No trips found',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _trips.length,
      itemBuilder: (context, index) {
        final trip = _trips[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _buildAnimatedTripCard(index, trip),
        );
      },
    );
  }

  Widget _buildAnimatedTripCard(int index, Trip trip) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(0.3 + index * 0.1, 1.0, curve: Curves.easeOut),
        ),
      ),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(0.3 + index * 0.1, 1.0, curve: Curves.easeIn),
          ),
        ),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        trip.route,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(trip.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        trip.status,
                        style: TextStyle(
                          color: _getStatusColor(trip.status),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  trip.dateTime,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTripDetail('Distance', trip.distance, Icons.navigation_rounded),
                    _buildTripDetail('Duration', trip.duration, Icons.access_time_rounded),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _viewTripDetails(trip.id);
                    },
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in progress':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      case 'scheduled':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildTripDetail(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF6366F1)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

// Data models for API responses
class Trip {
  final String id;
  final String route;
  final String dateTime;
  final String distance;
  final String duration;
  final String status;

  Trip({
    required this.id,
    required this.route,
    required this.dateTime,
    required this.distance,
    required this.duration,
    required this.status,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] ?? '',
      route: json['route'] ?? 'Unknown Route',
      dateTime: json['dateTime'] ?? 'Unknown Date',
      distance: json['distance'] ?? '0 km',
      duration: json['duration'] ?? '0h 0m',
      status: json['status'] ?? 'Unknown',
    );
  }
}

class MonthlyStats {
  final int totalTrips;
  final String totalDistance;

  MonthlyStats({
    this.totalTrips = 0,
    this.totalDistance = '0 km',
  });

  factory MonthlyStats.fromJson(Map<String, dynamic> json) {
    return MonthlyStats(
      totalTrips: json['totalTrips'] ?? 0,
      totalDistance: json['totalDistance'] ?? '0 km',
    );
  }
}