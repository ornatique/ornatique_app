import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [

                // SVG Logo Animation
                SvgPicture.asset(
                  'assets/logo.svg', // Ensure this exists in assets
                  height: 80,
                ).animate()
                    .fade(duration: 800.ms)
                    .moveY(begin: -30, end: 0),

                const SizedBox(height: 10),

                // Title Animation
                Text(
                  "Forgot Password?",
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ).animate()
                    .fade(delay: 300.ms)
                    .scale(duration: 400.ms),

                const SizedBox(height: 20),

                // Form Section
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Email Input Field
                      buildTextField("Enter your email", emailController, Icons.email).animate()
                          .fade(delay: 400.ms)
                          .slideY(begin: 0.2, end: 0),

                      const SizedBox(height: 20),

                      // Submit Button Animation
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              print("Password Reset Link Sent!");
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 50),
                          ),
                          child: Text(
                            "Reset Password",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ).animate()
                          .fade(delay: 600.ms)
                          .slideY(begin: 0.3, end: 0),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Reusable Text Field Widget
  Widget buildTextField(String hint, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.emailAddress,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Email is required";
          }
          return null;
        },
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.blue),
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
