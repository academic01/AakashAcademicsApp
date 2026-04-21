class AppValidators {
  // Email validation
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  // Password validation
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }

    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }

    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain lowercase letters';
    }

    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain uppercase letters';
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain numbers';
    }

    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(
    String? password,
    String? confirmPassword,
  ) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Confirm password is required';
    }

    if (password != confirmPassword) {
      return 'Passwords do not match';
    }

    return null;
  }

  // Phone number validation
  static String? validatePhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) {
      return 'Phone number is required';
    }

    final phoneRegex = RegExp(r'^[0-9]{10}$');

    if (!phoneRegex.hasMatch(phone.replaceAll(RegExp(r'[^\d]'), ''))) {
      return 'Please enter a valid 10-digit phone number';
    }

    return null;
  }

  // Name validation
  static String? validateName(String? name) {
    if (name == null || name.isEmpty) {
      return 'Name is required';
    }

    if (name.length < 2) {
      return 'Name must be at least 2 characters';
    }

    if (name.length > 50) {
      return 'Name must not exceed 50 characters';
    }

    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(name)) {
      return 'Name can only contain letters and spaces';
    }

    return null;
  }

  // Roll number validation
  static String? validateRollNumber(String? rollNumber) {
    if (rollNumber == null || rollNumber.isEmpty) {
      return 'Roll number is required';
    }

    if (rollNumber.length < 3) {
      return 'Roll number is invalid';
    }

    return null;
  }

  // School name validation
  static String? validateSchoolName(String? schoolName) {
    if (schoolName == null || schoolName.isEmpty) {
      return 'School name is required';
    }

    if (schoolName.length < 3) {
      return 'School name must be at least 3 characters';
    }

    return null;
  }

  // Class validation
  static String? validateClass(String? className) {
    if (className == null || className.isEmpty) {
      return 'Class is required';
    }

    final validClasses = ['6', '7', '8', '9', '10', '11', '12'];
    if (!validClasses.contains(className)) {
      return 'Invalid class selected';
    }

    return null;
  }

  // Generic non-empty validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    return null;
  }

  // OTP validation
  static String? validateOTP(String? otp) {
    if (otp == null || otp.isEmpty) {
      return 'OTP is required';
    }

    if (!RegExp(r'^[0-9]{6}$').hasMatch(otp)) {
      return 'Please enter a valid 6-digit OTP';
    }

    return null;
  }

  // URL validation
  static String? validateURL(String? url) {
    if (url == null || url.isEmpty) {
      return 'URL is required';
    }

    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );

    if (!urlRegex.hasMatch(url)) {
      return 'Please enter a valid URL';
    }

    return null;
  }
}
