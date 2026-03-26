import 'package:flutter/material.dart';
import '../driver/auth/driver_signup_screen.dart';
import 'user_signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // This function shows the sleek slide-up menu for registration
  void _showSignUpOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Join Chonh Choun',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('How would you like to use the app?'),
              const SizedBox(height: 24),
              
           // Option 1: User / Passenger
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.blue),
                ),
                title: const Text('Sign up as a User', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Book rides and deliveries'),
                onTap: () {
                  Navigator.pop(context); // Close the bottom sheet first!
                  
                  // Navigate to your brand new User Signup Screen
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => const UserSignupScreen())
                  );
                },
              ),
              // Option 2: Agent / Driver
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_shipping, color: Colors.green),
                ),
                title: const Text('Sign up as an Agent', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Drive and earn with us'),
                onTap: () {
                  Navigator.pop(context); // Close the bottom sheet
                  // Navigate to the Driver Signup Screen we built earlier!
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const DriverSignupScreen()));
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            
            Image.asset(
              'assets/images/openingVehicle.png',
              height: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 32),
            
            const Text(
              'Welcome Back!',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2C5F8A)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Login to continue',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Unified Login Form Fields
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),

            // Login Button
            ElevatedButton(
              onPressed: () {
                
                print('Logging in with ${_phoneController.text}');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C5F8A),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Login', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
            
            const SizedBox(height: 16),

            // The Sign Up Trigger
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account?"),
                TextButton(
                  onPressed: () => _showSignUpOptions(context), // Triggers the Bottom Sheet
                  child: const Text(
                    "Sign Up", 
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C5F8A))
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}