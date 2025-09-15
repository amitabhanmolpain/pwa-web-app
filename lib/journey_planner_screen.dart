import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const JourneyPlannerApp());
}

class JourneyPlannerApp extends StatelessWidget {
  const JourneyPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Journey Planner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const JourneyPlannerScreen(),
    );
  }
}

class JourneyPlannerScreen extends StatefulWidget {
  const JourneyPlannerScreen({super.key});

  @override
  State<JourneyPlannerScreen> createState() => _JourneyPlannerScreenState();
}

class _JourneyPlannerScreenState extends State<JourneyPlannerScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _tripButtonAnimationController;
  late Animation<double> _buttonScaleAnimation;

  // Text editing controllers for search fields
  final TextEditingController _startPointController = TextEditingController();
  final TextEditingController _endPointController = TextEditingController();

  // Focus nodes for search fields
  final FocusNode _startPointFocus = FocusNode();
  final FocusNode _endPointFocus = FocusNode();

  // API endpoints
  static const String BASE_URL = 'http://your-spring-boot-server:8080/api';
  static const String PLAN_ROUTE_ENDPOINT = '$BASE_URL/routes/plan';
  static const String ROUTE_DETAILS_ENDPOINT = '$BASE_URL/routes';
  static const String UPCOMING_STOPS_ENDPOINT = '$BASE_URL/routes/stops';

  // Route data
  String routeName = "Route Planning";
  String currentLocation = "Enter starting point";
  String destination = "Enter destination";
  String routeId = "";
  bool _tripStarted = false;
  bool _isLoading = false;
  List<UpcomingStop> upcomingStops = [];

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _tripButtonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _buttonScaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _tripButtonAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Start button pulsing animation
    _tripButtonAnimationController.repeat(reverse: true);
    
    // Auto-focus on the starting point field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_startPointFocus);
    });
  }

  @override
  void dispose() {
    _tripButtonAnimationController.dispose();
    _startPointController.dispose();
    _endPointController.dispose();
    _startPointFocus.dispose();
    _endPointFocus.dispose();
    super.dispose();
  }

  // Function to handle start trip button tap with API call
  Future<void> _handleStartTrip() async {
    if (_startPointController.text.isEmpty || _endPointController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter both starting point and destination"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Stop the pulsing animation
    _tripButtonAnimationController.stop();
    
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      
      if (accessToken == null) {
        throw Exception('Not authenticated. Please login again.');
      }

      // Call API to plan route
      final response = await http.post(
        Uri.parse(PLAN_ROUTE_ENDPOINT),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'startLocation': _startPointController.text.trim(),
          'endLocation': _endPointController.text.trim(),
          'vehicleId': 'default', // You might want to get this from user profile
          'driverId': prefs.getString('user_id'),
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        setState(() {
          routeId = responseData['routeId'];
          routeName = responseData['routeName'] ?? 'Planned Route';
          currentLocation = _startPointController.text;
          destination = _endPointController.text;
          _tripStarted = true;
        });

        // Fetch route details and upcoming stops
        await _fetchRouteDetails();
        await _fetchUpcomingStops();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Trip started successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        final newToken = await _refreshToken();
        if (newToken != null) {
          await _handleStartTrip(); // Retry with new token
          return;
        } else {
          throw Exception('Session expired. Please login again.');
        }
      } else {
        throw Exception('Failed to plan route: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
      _tripButtonAnimationController.repeat(reverse: true);
    }
  }

  // Fetch route details from backend
  Future<void> _fetchRouteDetails() async {
    if (routeId.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      
      final response = await http.get(
        Uri.parse('$ROUTE_DETAILS_ENDPOINT/$routeId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final routeData = json.decode(response.body);
        setState(() {
          routeName = routeData['name'] ?? routeName;
          // You can update other route details here
        });
      }
    } catch (e) {
      print('Error fetching route details: $e');
    }
  }

  // Fetch upcoming stops from backend
  Future<void> _fetchUpcomingStops() async {
    if (routeId.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      
      final response = await http.get(
        Uri.parse('$UPCOMING_STOPS_ENDPOINT/$routeId/upcoming'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final stopsData = json.decode(response.body);
        final List<dynamic> stopsList = stopsData['stops'] ?? [];
        
        setState(() {
          upcomingStops = stopsList.map((stop) {
            return UpcomingStop(
              name: stop['name'] ?? 'Unknown Stop',
              sequence: stop['sequence'] ?? 0,
              stopId: stop['stopId'] ?? '',
            );
          }).toList();
        });
      }
    } catch (e) {
      print('Error fetching upcoming stops: $e');
      // Fallback to empty list
      setState(() {
        upcomingStops = [];
      });
    }
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
        title: const Text("Route View"),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search fields (always shown at the top)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _startPointController,
                        focusNode: _startPointFocus,
                        decoration: InputDecoration(
                          labelText: 'Starting Point',
                          prefixIcon: const Icon(Icons.my_location, color: Colors.blue),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _endPointController,
                        focusNode: _endPointFocus,
                        decoration: InputDecoration(
                          labelText: 'Destination',
                          prefixIcon: const Icon(Icons.location_on, color: Colors.blue),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ScaleTransition(
                        scale: _buttonScaleAnimation,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleStartTrip,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Start Trip',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Only show route details after trip has been started
                if (_tripStarted) ...[
                  // Route information section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.blue[700],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          routeName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildLocationRow(Icons.my_location, currentLocation),
                        const SizedBox(height: 8),
                        _buildLocationRow(Icons.location_on, destination),
                      ],
                    ),
                  ),
                  
                  // Map view section
                  Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.map, size: 50, color: Colors.grey),
                          const SizedBox(height: 8),
                          const Text(
                            "Map View",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Route ID: $routeId",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Upcoming stops section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Upcoming Stops",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (upcomingStops.isEmpty)
                          const Center(
                            child: Text(
                              "No stops available for this route",
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: upcomingStops.length,
                            itemBuilder: (context, index) {
                              return _buildStopItem(upcomingStops[index], index + 1);
                            },
                          ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Show prompt to start a trip
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        "Enter your starting point and destination to plan your journey",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStopItem(UpcomingStop stop, int sequenceNumber) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                sequenceNumber.toString(),
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              stop.name,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
          // Removed estimated time as requested
        ],
      ),
    );
  }
}

// Data model for upcoming stops
class UpcomingStop {
  final String name;
  final int sequence;
  final String stopId;

  UpcomingStop({
    required this.name,
    required this.sequence,
    required this.stopId,
  });
}