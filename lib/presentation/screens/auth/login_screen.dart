import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/user_service.dart';
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
  int? _resendToken;
  final AuthService _authService = AuthService();

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

  void _startCountdown() {
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

  Future<void> _sendOTP() async {
    if (_phoneController.text.length != 10) {
      setState(() => _phoneError = 'Enter valid 10-digit number');
      return;
    }

    setState(() => _isLoading = true);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: '+91${_phoneController.text}',
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        if (mounted) context.go('/home');
      },
      codeSent: (verificationId, resendToken) {
        setState(() {
          _verificationId = verificationId;
          _resendToken = resendToken;
          _isLoading = false;
          _otpSent = true;
        });
        _startCountdown();
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() => _isLoading = false);

        String message = 'Failed to send OTP';

        if (e.code == 'invalid-phone-number') {
          message = 'Invalid phone number format';
        } else if (e.code == 'too-many-requests') {
          message = 'Too many requests. Wait before trying again.';
        } else if (e.code == 'quota-exceeded') {
          message = 'SMS quota exceeded. Try after some time.';
        } else if (e.code == 'app-not-authorized') {
          message = 'App not authorized. Check SHA-1 in Firebase.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      },
      codeAutoRetrievalTimeout: (verificationId) {
        _verificationId = verificationId;
      },
      forceResendingToken: _resendToken,
    );
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

  Future<void> _verifyOTP() async {
    final otp = _otpControllers.map((controller) => controller.text).join();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter complete 6-digit OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_verificationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please request OTP first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isVerifying = true);

    try {
      final result = await _authService.verifyOTP(
        verificationId: _verificationId!,
        otp: otp,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final user = result['user'] as UserModel;
        
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists && userDoc.data()?['isActive'] == false) {
          await _authService.signOut();
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();
          if (mounted) {
            context.go('/blocked');
          }
          return;
        }

        if (mounted) {
          context.read<UserProvider>().setUser(user);
          _goAfterAuth(user.isProfileComplete);
        }
      } else {
        setState(() => _isVerifying = false);
        _showSnackBar(
          (result['error'] as String?) ?? 'Verification failed',
          isError: true,
        );
        for (var c in _otpControllers) {
          c.clear();
        }
        _focusNodes[0].requestFocus();
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isVerifying = false);

      String message = 'Verification failed';
      if (e.code == 'invalid-verification-code') {
        message = 'Wrong OTP entered. Try again.';
      } else if (e.code == 'session-expired') {
        message = 'OTP expired. Please request new OTP.';
      }

      if (!mounted) return;
      _showSnackBar(message, isError: true);

      for (var c in _otpControllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
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
    setState(() => _isLoading = true);
    final result = await _authService.signInWithGoogle();
    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      final user = result['user'];
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        try {
          final canonicalUid = await UserService().resolveCanonicalUid(firebaseUser);
          if (canonicalUid != firebaseUser.uid) {
            await FirebaseAuth.instance.signOut();
            if (mounted) {
              _showMismatchDialog(firebaseUser.phoneNumber ?? '');
            }
            return;
          }
          await UserService().ensureUserDocument(firebaseUser);
          
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(canonicalUid)
              .get();
          
          if (userDoc.exists && userDoc.data()?['isActive'] == false) {
            await FirebaseAuth.instance.signOut();
            final prefs = await SharedPreferences.getInstance();
            await prefs.clear();
            if (mounted) {
              context.go('/blocked');
            }
            return;
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to initialize user document: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
      if (!mounted) return;
      context.read<UserProvider>().setUser(user);
      _goAfterAuth(user.isProfileComplete);
      return;
    }

    _showSnackBar(
      (result['error'] as String?) ?? 'Google sign-in failed.',
      isError: true,
    );
  }

  void _showMismatchDialog(String rawPhone) {
    String masked = rawPhone;
    if (rawPhone.length >= 10) {
      masked = rawPhone.replaceRange(rawPhone.length - 8, rawPhone.length - 2, '******');
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Account Exists'),
        content: Text('We found an existing account with this phone number ($masked). Sign in with OTP instead to access your saved progress, courses, and XP.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              setState(() {
                _otpSent = false;
                String localPhone = rawPhone.replaceAll('+91', '');
                _phoneController.text = localPhone;
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D2240)),
            child: const Text('Use Phone OTP Instead'),
          ),
        ],
      ),
    );
  }

  void _goAfterAuth(bool isProfileComplete) {
    if (isProfileComplete) {
      context.go('/home');
    } else {
      context.go('/complete-profile');
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF0D2240),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0D2240);
    final secondaryTextColor = isDark ? Colors.white70 : const Color(0xFF666666);
    final buttonColor = isDark ? const Color(0xFFF5A623) : const Color(0xFF0D2240);
    final buttonTextColor = isDark ? const Color(0xFF0A1628) : Colors.white;

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
                        color: Colors.white.withValues(alpha: 0.05),
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
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),

                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'AAKASH ACADEMICS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your Rank. Your Rules.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.70),
                            fontSize: 13,
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
                        Text(
                          'Welcome Back! 👋',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                        Text(
                          'Login to continue learning',
                          style: TextStyle(
                            fontSize: 14,
                            color: secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // PHONE INPUT
                        if (!_otpSent)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mobile Number',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: secondaryTextColor,
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
                                    backgroundColor: buttonColor,
                                    disabledBackgroundColor: buttonColor.withOpacity(0.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(26),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isLoading
                                      ? SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  buttonTextColor,
                                                ),
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          'Send OTP',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: buttonTextColor,
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
                                  ).withValues(alpha: 0.06),
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
                                    backgroundColor: buttonColor,
                                    disabledBackgroundColor: buttonColor.withOpacity(0.5),
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
                                            SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(buttonTextColor),
                                                strokeWidth: 2,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Verifying...',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: buttonTextColor,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Text(
                                          'Verify & Login',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: buttonTextColor,
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
                                Text(
                                  'Continue with Google',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
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
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? const Color(0xFFF5A623) : const Color(0xFF0D2240),
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
