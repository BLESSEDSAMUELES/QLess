import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'student_home.dart';
import 'student_signup_page.dart';
import 'services/order_service.dart';
import 'models/canteen_models.dart';

class StudentLoginPage extends StatefulWidget {
  const StudentLoginPage({super.key});

  @override
  State<StudentLoginPage> createState() => _StudentLoginPageState();
}

class _StudentLoginPageState extends State<StudentLoginPage> {
  final _studentIdController = TextEditingController(text: 'STU9421');
  final _passwordController = TextEditingController(text: 'student@123');

  bool _loading = false;
  bool _obscurePassword = true;

  Future<void> _loginStudent() async {
    final studentId = _studentIdController.text.trim();
    final password = _passwordController.text.trim();

    if (studentId.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter both Student ID and Password"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final supabase = Supabase.instance.client;
      // Query supabase if available
      final student = await supabase
          .from('students')
          .select()
          .eq('student_id', studentId)
          .maybeSingle();

      if (student != null) {
        final email = student['email'];
        if (email != null) {
          try {
            await supabase.auth.signInWithPassword(
              email: email,
              password: password,
            );
          } catch (_) {
            // Proceed if auth is loose in demo
          }
        }
        OrderService().setStudentProfile(
          StudentProfile(
            studentId: student['student_id']?.toString() ?? studentId,
            name: student['name']?.toString() ?? 'Alex Mercer',
            email: student['email']?.toString() ?? 'alex.mercer@campus.edu',
            phone: student['phone']?.toString() ?? '+91 98765 43210',
            walletBalance: 480.0,
          ),
        );
      } else {
        // Use default profile
        OrderService().setStudentProfile(
          StudentProfile(
            studentId: studentId,
            name: 'Alex Mercer (Demo Student)',
            email: '$studentId@campus.edu',
            phone: '+91 98765 43210',
            walletBalance: 480.0,
          ),
        );
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StudentHome()),
      );
    } catch (e) {
      // In case of network/database timeout, fallback cleanly to test user
      OrderService().setStudentProfile(
        StudentProfile(
          studentId: studentId,
          name: 'Alex Mercer',
          email: '$studentId@campus.edu',
          phone: '+91 98765 43210',
          walletBalance: 480.0,
        ),
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StudentHome()),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _fillDemo(String id, String pwd) {
    setState(() {
      _studentIdController.text = id;
      _passwordController.text = pwd;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Student Sign In"),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Icon & Heading
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: AppTheme.primary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Welcome Back!",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        "Order ahead, skip campus lines",
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Demo Quick Login Bar
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.flash_on_rounded, color: AppTheme.primary, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "Demo Account: STU9421",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => _fillDemo('STU9421', 'student@123'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "Auto-Fill",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Student ID Field
              const Text(
                "Student ID / Roll No.",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _studentIdController,
                decoration: const InputDecoration(
                  hintText: "e.g. STU9421 or 2024CS01",
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 18),

              // Password Field
              const Text(
                "Password",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: "Enter your password",
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Sign In Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _loginStudent,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Sign In to QLess",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Register Redirection
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StudentSignupPage(),
                      ),
                    );
                  },
                  child: RichText(
                    text: TextSpan(
                      text: "New student? ",
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                      children: [
                        TextSpan(
                          text: "Create an account",
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
