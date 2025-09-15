import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'setup_profile_documents_screen.dart';

class SetupProfileVehicleScreen extends StatefulWidget {
  const SetupProfileVehicleScreen({super.key});

  @override
  State<SetupProfileVehicleScreen> createState() => _SetupProfileVehicleScreenState();
}

class _SetupProfileVehicleScreenState extends State<SetupProfileVehicleScreen> {
  final TextEditingController _vehicleNumberController = TextEditingController();
  final TextEditingController _vehicleModelController = TextEditingController();
  final TextEditingController _seatingCapacityController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _selectedFuelType;
  bool _isLoading = false;
  bool _isSaving = false;

  // API endpoints
  static const String BASE_URL = 'http://your-spring-boot-server:8080/api';
  static const String VEHICLE_ENDPOINT = '$BASE_URL/driver/vehicle';
  static const String VEHICLE_TYPES_ENDPOINT = '$BASE_URL/vehicles/types';

  final List<String> fuelTypes = [
    'Petrol',
    'Diesel',
    'CNG',
    'Electric',
    'Hybrid'
  ];

  @override
  void initState() {
    super.initState();
    _loadVehicleData();
  }

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    _vehicleModelController.dispose();
    _seatingCapacityController.dispose();
    super.dispose();
  }

  // Load existing vehicle data
  Future<void> _loadVehicleData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      
      if (accessToken == null) {
        throw Exception('Not authenticated. Please login again.');
      }

      final response = await http.get(
        Uri.parse(VEHICLE_ENDPOINT),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final vehicleData = json.decode(response.body);
        setState(() {
          _vehicleNumberController.text = vehicleData['vehicleNumber'] ?? '';
          _vehicleModelController.text = vehicleData['model'] ?? '';
          _seatingCapacityController.text = vehicleData['seatingCapacity']?.toString() ?? '';
          _selectedFuelType = vehicleData['fuelType'];
        });
      } else if (response.statusCode == 401) {
        final newToken = await _refreshToken();
        if (newToken != null) {
          await _loadVehicleData();
          return;
        }
      }
      // If 404, it means no vehicle data exists yet - that's fine

    } catch (error) {
      print('Error loading vehicle data: $error');
      // Silently fail - user can enter new data
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Save vehicle data to backend
  Future<void> _saveVehicleData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      final userId = prefs.getString('user_id');
      
      if (accessToken == null) {
        throw Exception('Not authenticated. Please login again.');
      }

      if (_selectedFuelType == null) {
        throw Exception('Please select fuel type');
      }

      final response = await http.post(
        Uri.parse(VEHICLE_ENDPOINT),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'vehicleNumber': _vehicleNumberController.text.trim().toUpperCase(),
          'model': _vehicleModelController.text.trim(),
          'seatingCapacity': int.tryParse(_seatingCapacityController.text.trim()) ?? 0,
          'fuelType': _selectedFuelType,
          'userId': userId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Vehicle information saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to next screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SetupProfileDocumentsScreen()),
        );
      } else if (response.statusCode == 401) {
        final newToken = await _refreshToken();
        if (newToken != null) {
          await _saveVehicleData();
          return;
        }
      } else {
        throw Exception('Failed to save vehicle data: ${response.statusCode}');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving vehicle data: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
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

  // Validation methods
  String? _validateVehicleNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter vehicle number';
    }
    // Basic vehicle number validation (adjust based on your country's format)
    final vehicleRegex = RegExp(r'^[A-Z]{2}[ -]?[0-9]{1,2}[ -]?[A-Z]{1,2}[ -]?[0-9]{1,4}$');
    if (!vehicleRegex.hasMatch(value.toUpperCase())) {
      return 'Please enter a valid vehicle number';
    }
    return null;
  }

  String? _validateVehicleModel(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter vehicle model';
    }
    if (value.length < 2) {
      return 'Vehicle model must be at least 2 characters';
    }
    return null;
  }

  String? _validateSeatingCapacity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter seating capacity';
    }
    final capacity = int.tryParse(value);
    if (capacity == null || capacity <= 0) {
      return 'Please enter a valid seating capacity';
    }
    if (capacity > 100) {
      return 'Seating capacity cannot exceed 100';
    }
    return null;
  }

  String? _validateFuelType(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select fuel type';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Profile'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Progress Steps
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStep(1, 'Personal', false),
                        _buildStep(2, 'Vehicle', true),
                        _buildStep(3, 'Documents', false),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Form Fields with validation
                    _buildFormField(
                      'Vehicle Number',
                      'KA-01-AB-1234',
                      _vehicleNumberController,
                      validator: _validateVehicleNumber,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildFormField(
                      'Vehicle Model',
                      'Tata Starbus',
                      _vehicleModelController,
                      validator: _validateVehicleModel,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildFormField(
                      'Seating Capacity',
                      '40',
                      _seatingCapacityController,
                      validator: _validateSeatingCapacity,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    
                    // Fuel Type Dropdown with validation
                    const Text(
                      'Fuel Type',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedFuelType,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: fuelTypes.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedFuelType = newValue;
                        });
                      },
                      validator: _validateFuelType,
                      hint: const Text('Select fuel type'),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Navigation Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSaving ? null : () {
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Back'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveVehicleData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Next'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStep(int number, String title, bool isActive) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF6366F1) : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number.toString(),
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: isActive ? const Color(0xFF6366F1) : Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFormField(
    String label,
    String hint,
    TextEditingController controller, {
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}