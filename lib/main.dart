import 'package:flutter/material.dart';
import 'home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Health Bharat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C56F5),
          primary: const Color(0xFF6C56F5),
          secondary: const Color(0xFFF5A56C),
        ),
        useMaterial3: true,
      ),
      home: const AuthScreen(),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    
    // Mock login delay
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    
    // For now, accept any valid input
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
    
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const NetworkImage('https://i.ibb.co/rKGX0Nd9/bg.png'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.3),
                  BlendMode.darken,
                ),
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.2)),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: FadeTransition(
                  opacity: _animation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Column(
                        children: [
                          Icon(Icons.medical_services, size: 60, color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Digital Health Bharat',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Your health, our priority',
                            style: TextStyle(fontSize: 16, color: Colors.white70),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: _buildLoginForm(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        const Text('Login to your account',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 24),
        _buildTextField(_emailController, 'Email', Icons.email),
        const SizedBox(height: 16),
        _buildTextField(_passwordController, 'Password', Icons.lock, obscure: true),
        const SizedBox(height: 24),
        _buildSubmitButton('Login', _signIn),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon,
      {bool obscure = false, TextInputType inputType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter your $label';
        if (label == 'Email' && !value.contains('@')) return 'Please enter a valid email';
        if (label == 'Password' && value.length < 6) return 'Password must be at least 6 characters';
        return null;
      },
    );
  }

  Widget _buildSubmitButton(String label, Function() onPressed) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6C56F5),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        minimumSize: const Size(double.infinity, 50),
      ),
      child: Text(label),
    );
  }
}
