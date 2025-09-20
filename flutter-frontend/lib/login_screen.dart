// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'language_selection_screen.dart';
// import 'ForgotPasswordScreen.dart';
// import 'SignUpScreen.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _formKey = GlobalKey<FormState>();
//   bool _isLoading = false;

//   // API endpoints - update with your actual Spring Boot backend URLs
//   static const String BASE_URL = 'http://localhost:8080/api';
//   static const String LOGIN_ENDPOINT = '$BASE_URL/auth/login';
//   static const String REFRESH_TOKEN_ENDPOINT = '$BASE_URL/auth/refresh';

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   // Function to handle login process
//   Future<void> _handleLogin() async {
//     if (_formKey.currentState!.validate()) {
//       setState(() {
//         _isLoading = true;
//       });

//       try {
//         final loginSuccess = await _authenticateUser(
//           _emailController.text.trim(),
//           _passwordController.text.trim(),
//         );

//         if (loginSuccess) {
//           // Navigate to Language Selection Screen on successful login
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//               builder: (context) => const LanguageSelectionScreen(),
//             ),
//           );
//         } else {
//           _showErrorDialog('Login Failed', 'Invalid email or password');
//         }
//       } catch (e) {
//         _showErrorDialog('Login Error', 'A Backend error occurred: ');
//       } finally {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   // JWT Authentication with Spring Boot backend
//   Future<bool> _authenticateUser(String email, String password) async {
//     try {
//       final response = await http.post(
//         Uri.parse(LOGIN_ENDPOINT),
//         headers: {
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//         },
//         body: json.encode({
//           'email': email,
//           'password': password,
//         }),
//       );

//       if (response.statusCode == 200) {
//         // Parse the response
//         final Map<String, dynamic> responseData = json.decode(response.body);
        
//         // Extract tokens from response
//         final String accessToken = responseData['accessToken'];
//         final String refreshToken = responseData['refreshToken'];
//         final int expiresIn = responseData['expiresIn'] ?? 3600; // Default 1 hour
        
//         // Store tokens securely
//         await _storeTokens(accessToken, refreshToken, expiresIn);
        
//         // Store user info if available
//         if (responseData.containsKey('user')) {
//           await _storeUserInfo(responseData['user']);
//         }
        
//         return true;
//       } else if (response.statusCode == 401) {
//         throw Exception('Invalid credentials');
//       } else if (response.statusCode == 403) {
//         throw Exception('Account not verified or disabled');
//       } else {
//         throw Exception('Server error: ${response.statusCode}');
//       }
//     } catch (e) {
//       rethrow;
//     }
//   }

//   // Store JWT tokens securely
//   Future<void> _storeTokens(String accessToken, String refreshToken, int expiresIn) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('access_token', accessToken);
//     await prefs.setString('refresh_token', refreshToken);
//     await prefs.setInt('token_expiry', DateTime.now().millisecondsSinceEpoch + (expiresIn * 1000));
//   }

//   // Store user information
//   Future<void> _storeUserInfo(Map<String, dynamic> userInfo) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('user_email', userInfo['email'] ?? '');
//     await prefs.setString('user_name', userInfo['name'] ?? '');
//     await prefs.setString('user_id', userInfo['id']?.toString() ?? '');
//     await prefs.setString('user_role', userInfo['role'] ?? 'driver');
//   }

//   // Function to refresh JWT token
//   Future<String?> refreshToken() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final refreshToken = prefs.getString('refresh_token');
      
//       if (refreshToken == null) {
//         return null;
//       }

//       final response = await http.post(
//         Uri.parse(REFRESH_TOKEN_ENDPOINT),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $refreshToken',
//         },
//       );

//       if (response.statusCode == 200) {
//         final Map<String, dynamic> responseData = json.decode(response.body);
//         final String newAccessToken = responseData['accessToken'];
//         final int expiresIn = responseData['expiresIn'] ?? 3600;
        
//         await prefs.setString('access_token', newAccessToken);
//         await prefs.setInt('token_expiry', DateTime.now().millisecondsSinceEpoch + (expiresIn * 1000));
        
//         return newAccessToken;
//       } else {
//         // Refresh token failed, user needs to login again
//         await _clearStoredData();
//         return null;
//       }
//     } catch (e) {
//       await _clearStoredData();
//       return null;
//     }
//   }

//   // Clear stored authentication data
//   Future<void> _clearStoredData() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove('access_token');
//     await prefs.remove('refresh_token');
//     await prefs.remove('token_expiry');
//     await prefs.remove('user_email');
//     await prefs.remove('user_name');
//     await prefs.remove('user_id');
//     await prefs.remove('user_role');
//   }

//   // Check if user is already logged in (for auto-login)
//   Future<bool> checkExistingLogin() async {
//     final prefs = await SharedPreferences.getInstance();
//     final accessToken = prefs.getString('access_token');
//     final tokenExpiry = prefs.getInt('token_expiry');
    
//     if (accessToken == null || tokenExpiry == null) {
//       return false;
//     }
    
//     // Check if token is expired
//     if (DateTime.now().millisecondsSinceEpoch >= tokenExpiry) {
//       // Try to refresh token
//       final newToken = await refreshToken();
//       return newToken != null;
//     }
    
//     return true;
//   }

//   // Function to show error dialog
//   void _showErrorDialog(String title, String message) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text(title),
//           content: Text(message),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: const Text('OK'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // Function to handle forgot password
//   void _handleForgotPassword() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
//     );
//   }

//   // Function to handle sign up navigation
//   void _handleSignUp() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => const SignUpScreen()),
//     );
//   }

//   // Function to skip to language screen (for testing)
//   void _skipToLanguageScreen() {
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(
//         builder: (context) => const LanguageSelectionScreen(),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Color(0xFF6366F1), // Indigo
//               Color(0xFF8B5CF6), // Purple
//               Color(0xFFA855F7), // Purple
//             ],
//           ),
//         ),
//         child: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.all(24.0),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Spacer(),
//                 // Logo and Title Section
//                 Column(
//                   children: [
//                     Container(
//                       width: 80,
//                       height: 80,
//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(0.2),
//                         shape: BoxShape.circle,
//                       ),
//                       child: const Icon(
//                         Icons.local_shipping_outlined,
//                         color: Colors.white,
//                         size: 40,
//                       ),
//                     ),
//                     const SizedBox(height: 24),
//                     const Text(
//                       'DriverPortal',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 32,
//                         fontWeight: FontWeight.bold,
//                         fontFamily: 'Cursive',
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Your journey starts here',
//                       style: TextStyle(
//                         color: Colors.white.withOpacity(0.8),
//                         fontSize: 16,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 48),
                
//                 // Form Section
//                 Form(
//                   key: _formKey,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Email Field
//                       Text(
//                         'Email',
//                         style: TextStyle(
//                           color: Colors.white.withOpacity(0.9),
//                           fontSize: 16,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Container(
//                         decoration: BoxDecoration(
//                           color: Colors.white.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(12),
//                           border: Border.all(
//                             color: Colors.white.withOpacity(0.2),
//                           ),
//                         ),
//                         child: TextFormField(
//                           controller: _emailController,
//                           keyboardType: TextInputType.emailAddress,
//                           style: const TextStyle(color: Colors.white),
//                           decoration: InputDecoration(
//                             hintText: 'Enter your email',
//                             hintStyle: TextStyle(
//                               color: Colors.white.withOpacity(0.6),
//                             ),
//                             prefixIcon: Icon(
//                               Icons.email_outlined,
//                               color: Colors.white.withOpacity(0.7),
//                             ),
//                             border: InputBorder.none,
//                             contentPadding: const EdgeInsets.symmetric(
//                               horizontal: 16,
//                               vertical: 16,
//                             ),
//                           ),
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return 'Please enter your email';
//                             }
//                             if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
//                                 .hasMatch(value)) {
//                               return 'Please enter a valid email';
//                             }
//                             return null;
//                           },
//                         ),
//                       ),
//                       const SizedBox(height: 24),
                      
//                       // Password Field
//                       Text(
//                         'Password',
//                         style: TextStyle(
//                           color: Colors.white.withOpacity(0.9),
//                           fontSize: 16,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Container(
//                         decoration: BoxDecoration(
//                           color: Colors.white.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(12),
//                           border: Border.all(
//                             color: Colors.white.withOpacity(0.2),
//                           ),
//                         ),
//                         child: TextFormField(
//                           controller: _passwordController,
//                           obscureText: true,
//                           style: const TextStyle(color: Colors.white),
//                           decoration: InputDecoration(
//                             hintText: 'Enter your password',
//                             hintStyle: TextStyle(
//                               color: Colors.white.withOpacity(0.6),
//                             ),
//                             prefixIcon: Icon(
//                               Icons.lock_outlined,
//                               color: Colors.white.withOpacity(0.7),
//                             ),
//                             border: InputBorder.none,
//                             contentPadding: const EdgeInsets.symmetric(
//                               horizontal: 16,
//                               vertical: 16,
//                             ),
//                           ),
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return 'Please enter your password';
//                             }
//                             if (value.length < 6) {
//                               return 'Password must be at least 6 characters';
//                             }
//                             return null;
//                           },
//                         ),
//                       ),
//                       const SizedBox(height: 32),
                      
//                       // Sign In Button
//                       SizedBox(
//                         width: double.infinity,
//                         child: ElevatedButton(
//                           onPressed: _isLoading ? null : _handleLogin,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.white,
//                             foregroundColor: const Color(0xFF6366F1),
//                             padding: const EdgeInsets.symmetric(vertical: 16),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             elevation: 0,
//                           ),
//                           child: _isLoading
//                               ? const SizedBox(
//                                   width: 20,
//                                   height: 20,
//                                   child: CircularProgressIndicator(
//                                     valueColor: AlwaysStoppedAnimation<Color>(
//                                         Color(0xFF6366F1)),
//                                     strokeWidth: 2,
//                                   ),
//                                 )
//                               : const Text(
//                                   'Sign In',
//                                   style: TextStyle(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                 ),
//                         ),
//                       ),
//                       const SizedBox(height: 24),
                      
//                       // Forgot Password
//                       Center(
//                         child: TextButton(
//                           onPressed: _handleForgotPassword,
//                           child: Text(
//                             'Forgot Password?',
//                             style: TextStyle(
//                               color: Colors.white.withOpacity(0.8),
//                               fontSize: 16,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
                
//                 // Test Navigation Button
//                 Container(
//                   width: double.infinity,
//                   margin: const EdgeInsets.symmetric(vertical: 16),
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Colors.white.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(color: Colors.white.withOpacity(0.3)),
//                   ),
//                   child: Column(
//                     children: [
//                       Icon(
//                         Icons.bug_report,
//                         color: Colors.white.withOpacity(0.8),
//                         size: 24,
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         'Testing Mode',
//                         style: TextStyle(
//                           fontWeight: FontWeight.w600,
//                           color: Colors.white.withOpacity(0.9),
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       ElevatedButton(
//                         onPressed: _skipToLanguageScreen,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.white.withOpacity(0.2),
//                           foregroundColor: Colors.white,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                         ),
//                         child: const Text('Skip to Language Screen'),
//                       ),
//                     ],
//                   ),
//                 ),
                
//                 const Spacer(),
                
//                 // Sign Up Link
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text(
//                       "Don't have an account? ",
//                       style: TextStyle(
//                         color: Colors.white.withOpacity(0.8),
//                         fontSize: 14,
//                       ),
//                     ),
//                     TextButton(
//                       onPressed: _handleSignUp,
//                       style: TextButton.styleFrom(
//                         padding: EdgeInsets.zero,
//                         minimumSize: Size.zero,
//                         tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                       ),
//                       child: const Text(
//                         'Sign Up',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 14,
//                           fontWeight: FontWeight.w600,
//                           decoration: TextDecoration.underline,
//                           decorationColor: Colors.white,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 24),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'language_selection_screen.dart';
import 'ForgotPasswordScreen.dart';
import 'SignUpScreen.dart';
import 'dart:developer' as developer;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late final String BASE_URL;
  late final String LOGIN_ENDPOINT;
  late final String REFRESH_TOKEN_ENDPOINT;

  @override
  void initState() {
    super.initState();
    _initializeEndpoints();
    _checkAutoLogin();
  }

  Future<void> _initializeEndpoints() async {
    try {
      BASE_URL = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8080/api';
      LOGIN_ENDPOINT = '$BASE_URL/auth/login';
      REFRESH_TOKEN_ENDPOINT = '$BASE_URL/auth/refresh';
    } catch (e) {
      developer.log('Error initializing endpoints: $e', name: 'LoginScreen');
      BASE_URL = 'http://localhost:8080/api';
      LOGIN_ENDPOINT = '$BASE_URL/auth/login';
      REFRESH_TOKEN_ENDPOINT = '$BASE_URL/auth/refresh';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkAutoLogin() async {
    final isLoggedIn = await checkExistingLogin();
    if (isLoggedIn && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LanguageSelectionScreen(),
        ),
      );
    }
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final loginSuccess = await _authenticateUser(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        if (loginSuccess && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const LanguageSelectionScreen(),
            ),
          );
        } else {
          _showErrorDialog('Login Failed', 'Invalid email or password');
        }
      } catch (e) {
        _showErrorDialog('Login Error', e.toString());
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<bool> _authenticateUser(String email, String password) async {
    try {
      developer.log('Attempting login for $email', name: 'LoginScreen');
      final response = await http
          .post(
            Uri.parse(LOGIN_ENDPOINT),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 30));

      developer.log('Login response: ${response.statusCode}', name: 'LoginScreen');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final String accessToken = responseData['token'];
        final int expiresIn = 3600; // Default 1 hour since not provided

        await _storeTokens(accessToken, expiresIn);
        if (responseData.containsKey('user')) {
          await _storeUserInfo(responseData['user']);
        }
        return true;
      } else {
        String errorMessage;
        switch (response.statusCode) {
          case 400:
            errorMessage = 'Bad request. Please check your input.';
            break;
          case 401:
            errorMessage = 'Invalid email or password.';
            break;
          case 403:
            errorMessage = 'Account not verified or disabled.';
            break;
          case 500:
            errorMessage = 'Server error. Please try again later.';
            break;
          default:
            errorMessage = 'Unexpected error: ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      developer.log('Login error: $e', name: 'LoginScreen');
      throw Exception('Authentication failed: $e');
    }
  }

  Future<void> _storeTokens(String accessToken, int expiresIn) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'access_token', value: accessToken);
    await storage.write(key: 'token_expiry', value: (DateTime.now().millisecondsSinceEpoch + (expiresIn * 1000)).toString());
  }

  Future<void> _storeUserInfo(Map<String, dynamic> userInfo) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'user_email', value: userInfo['email'] ?? '');
    await storage.write(key: 'user_name', value: userInfo['name'] ?? '');
    await storage.write(key: 'user_id', value: userInfo['id']?.toString() ?? '');
    await storage.write(key: 'user_role', value: userInfo['role'] ?? 'driver');
  }

  Future<String?> refreshToken() async {
    try {
      const storage = FlutterSecureStorage();
      final refreshToken = await storage.read(key: 'refresh_token');

      if (refreshToken == null) {
        developer.log('No refresh token available', name: 'LoginScreen');
        await _clearStoredData();
        return null;
      }

      developer.log('Attempting token refresh', name: 'LoginScreen');
      final response = await http
          .post(
            Uri.parse(REFRESH_TOKEN_ENDPOINT),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode({
              'refreshToken': refreshToken,
            }),
          )
          .timeout(const Duration(seconds: 30));

      developer.log('Refresh token response: ${response.statusCode}', name: 'LoginScreen');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final String newAccessToken = responseData['token'];
        final int expiresIn = responseData['expiresIn'] ?? 3600;

        await storage.write(key: 'access_token', value: newAccessToken);
        await storage.write(key: 'token_expiry', value: (DateTime.now().millisecondsSinceEpoch + (expiresIn * 1000)).toString());

        return newAccessToken;
      } else {
        await _clearStoredData();
        return null;
      }
    } catch (e) {
      developer.log('Refresh token error: $e', name: 'LoginScreen');
      await _clearStoredData();
      return null;
    }
  }

  Future<void> _clearStoredData() async {
    const storage = FlutterSecureStorage();
    await storage.deleteAll();
  }

  Future<bool> checkExistingLogin() async {
    const storage = FlutterSecureStorage();
    final accessToken = await storage.read(key: 'access_token');
    final tokenExpiry = await storage.read(key: 'token_expiry');

    if (accessToken == null || tokenExpiry == null) {
      return false;
    }

    if (DateTime.now().millisecondsSinceEpoch >= int.parse(tokenExpiry)) {
      developer.log('Token expired, clearing data', name: 'LoginScreen');
      await _clearStoredData();
      return false; // Prompt login again since refresh token is not supported
    }

    return true;
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _handleForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
    );
  }

  void _handleSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignUpScreen()),
    );
  }

  void _skipToLanguageScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LanguageSelectionScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AbsorbPointer(
        absorbing: _isLoading,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF6366F1),
                Color(0xFF8B5CF6),
                Color(0xFFA855F7),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_shipping_outlined,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'DriverPortal',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cursive',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your journey starts here',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Email',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Enter your email',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                              ),
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Password',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Enter your password',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outlined,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF6366F1),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Color(0xFF6366F1)),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: TextButton(
                            onPressed: _isLoading ? null : _handleForgotPassword,
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.bug_report,
                          color: Colors.white.withOpacity(0.8),
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Testing Mode',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _skipToLanguageScreen,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Skip to Language Screen'),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: _isLoading ? null : _handleSignUp,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}