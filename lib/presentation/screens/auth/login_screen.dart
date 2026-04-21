import 'dart:async';
import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/user_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController _phoneController;
  late List<TextEditingController> _otpControllers;
  late List<FocusNode> _focusNodes;
  bool _isLoading = false;
  bool _isVerifying = false;
  bool _otpSent = false;
  int _countdown = 60;
  Timer? _timer;
  String? _phoneError;
  String? _verificationId;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    _otpControllers = List.generate(6, (_) => TextEditingController());
    _focusNodes = List.generate(6, (_) => FocusNode());
  }

  @override
  void dispose() {
    _phoneController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _countdown = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _countdown--;
        if (_countdown == 0) {
          _timer?.cancel();
        }
      });
    });
  }

  void _sendOTP() async {
    final phone = _phoneController.text.trim();

    if (phone.length != 10) {
      setState(() => _phoneError = 'Please enter valid 10-digit number');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Simulate OTP sending (Replace with actual Firebase Phone Auth)
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        setState(() {
          _isLoading = false;
          _otpSent = true;
          _phoneError = null;
          _verificationId =
              'sim_${phone}_${DateTime.now().millisecondsSinceEpoch}';
        });
        _startTimer();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _phoneError = 'Failed to send OTP. Try again.';
      });
    }
  }

  void _onOtpDigitChanged(int index, String value) {
    if (value.length > 1) {
      _otpControllers[index].text = value[value.length - 1];
      return;
    }

    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Auto-verify when all 6 digits are filled
    if (_allOtpFilled()) {
      _verifyOTP();
    }
  }

  bool _allOtpFilled() {
    return _otpControllers.every((controller) => controller.text.isNotEmpty);
  }

  void _verifyOTP() async {
    final otp = _otpControllers.map((controller) => controller.text).join();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isVerifying = true);

    try {
      // Simulate API call (Replace with actual Firebase Auth)
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();

      // Create user model with phone
      final user = UserModel(
        uid: 'user_${_phoneController.text}',
        phone: _phoneController.text,
        isNewUser: true,
        isProfileComplete: false,
        token: 'token_${_phoneController.text}',
        createdAt: DateTime.now(),
      );

      // Save to SharedPreferences
      await prefs.setString('user', jsonEncode(user.toJson()));
      await prefs.setString('token', user.token!);
      await prefs.setBool('isLoggedIn', true);
      await prefs.setBool('isNewUser', true);

      // Update provider
      if (mounted) {
        context.read<UserProvider>().setUser(user);

        setState(() => _isVerifying = false);

        // Navigate to complete profile screen
        context.go('/complete-profile');
      }
    } catch (e) {
      setState(() => _isVerifying = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        // Clear OTP boxes
        for (var c in _otpControllers) {
          c.clear();
        }
        _focusNodes[0].requestFocus();
      }
    }
  }

  void _resendOTP() {
    if (_countdown == 0) {
      for (var controller in _otpControllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
      _sendOTP();
    }
  }

  void _signInWithGoogle() async {
    // TODO: Implement Google Sign-in with proper OAuth flow
    // For now, show a placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Google Sign-in coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final phoneForDisplay = _phoneController.text.length == 10
        ? _phoneController.text
        : 'XXXXXXXXXX';

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // TOP GRADIENT SECTION
            Container(
              height: 220,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF0D2240), const Color(0xFF1a3a52)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Stack(
                children: [
                  // Decorative circles
                  Positioned(
                    top: -30,
                    right: -30,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -20,
                    left: -20,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),

                  // Center content
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Center(
                            child: Text(
                              'A',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'AAKASH ACADEMICS',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your Rank. Your Rules.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // FORM CARD
            Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome Back! 👋',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0D2240),
                          ),
                        ),
                        const Text(
                          'Login to continue learning',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF888888),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // PHONE INPUT
                        if (!_otpSent)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Mobile Number',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF666666),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _phoneError != null
                                        ? Colors.red
                                        : const Color(0xFFE5E7EB),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  color: const Color(0xFFF9F9F9),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF0D2240),
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(11),
                                          bottomLeft: Radius.circular(11),
                                        ),
                                      ),
                                      child: const Text(
                                        '+91',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller: _phoneController,
                                        keyboardType: TextInputType.number,
                                        maxLength: 10,
                                        decoration: const InputDecoration(
                                          hintText: 'Enter 10-digit number',
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                          counterText: '',
                                        ),
                                        onChanged: (_) {
                                          setState(() => _phoneError = null);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_phoneError != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _phoneError!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),

                              // SEND OTP BUTTON
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _sendOTP,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0D2240),
                                    disabledBackgroundColor: const Color(
                                      0xFF0D2240,
                                    ).withOpacity(0.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(26),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'Send OTP',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),

                        // OTP VERIFICATION SECTION
                        if (_otpSent)
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF0D2240,
                                  ).withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.mail_outline,
                                      color: Color(0xFF0D2240),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'OTP sent to +91${_phoneController.text}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF666666),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Enter OTP',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF666666),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // OTP INPUT BOXES
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: List.generate(
                                  6,
                                  (index) => SizedBox(
                                    width: 44,
                                    height: 55,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color:
                                              _otpControllers[index]
                                                  .text
                                                  .isNotEmpty
                                              ? const Color(0xFF0D2240)
                                              : const Color(0xFFE5E7EB),
                                          width:
                                              _otpControllers[index]
                                                  .text
                                                  .isNotEmpty
                                              ? 2
                                              : 1,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.white,
                                      ),
                                      child: TextField(
                                        controller: _otpControllers[index],
                                        focusNode: _focusNodes[index],
                                        keyboardType: TextInputType.number,
                                        maxLength: 1,
                                        textAlign: TextAlign.center,
                                        autofocus: index == 0,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0D2240),
                                        ),
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          counterText: '',
                                        ),
                                        onChanged: (value) =>
                                            _onOtpDigitChanged(index, value),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // RESEND TIMER
                              Center(
                                child: _countdown > 0
                                    ? Text(
                                        'Resend OTP in ${_countdown}s',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF666666),
                                        ),
                                      )
                                    : GestureDetector(
                                        onTap: _resendOTP,
                                        child: const Text(
                                          'Resend OTP',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF0D2240),
                                            fontWeight: FontWeight.w600,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 16),

                              // VERIFY BUTTON
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isVerifying ? null : _verifyOTP,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0D2240),
                                    disabledBackgroundColor: const Color(
                                      0xFF0D2240,
                                    ).withOpacity(0.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(26),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isVerifying
                                      ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                                strokeWidth: 2,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            const Text(
                                              'Verifying...',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        )
                                      : const Text(
                                          'Verify & Login',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 16),

                        // DIVIDER
                        const Row(
                          children: [
                            Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                '── OR ──',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF888888),
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // GOOGLE BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton(
                            onPressed: _signInWithGoogle,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color(0xFFE5E7EB),
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(26),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF4285F4),
                                      width: 2,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'G',
                                      style: TextStyle(
                                        color: Color(0xFF4285F4),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Continue with Google',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0D2240),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // SIGNUP LINK
                        Center(
                          child: RichText(
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text: 'New here? ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF888888),
                                  ),
                                ),
                                TextSpan(
                                  text: 'Create Account',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0D2240),
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      context.go('/signup');
                                    },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
