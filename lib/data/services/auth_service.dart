import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

import '../models/user_model.dart';
import 'student_profile_service.dart';

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;
  final StudentProfileService _studentProfileService = StudentProfileService();

  Future<void> sendOTP({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String message) onError,
    required Future<void> Function(UserModel user) onAutoVerified,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: '+91$phoneNumber',
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          final result = await _signInWithCredential(credential);
          if (result['success'] == true) {
            await onAutoVerified(result['user'] as UserModel);
            return;
          }
          onError((result['error'] as String?) ?? 'Auto verification failed.');
        },
        verificationFailed: (e) {
          if (e.code == 'invalid-phone-number') {
            onError('Invalid phone number.');
          } else if (e.code == 'too-many-requests') {
            onError('Too many attempts. Please try again later.');
          } else {
            onError(e.message ?? 'Failed to send OTP.');
          }
        },
        codeSent: (verificationId, _) => onCodeSent(verificationId),
        codeAutoRetrievalTimeout: (_) {},
      );
    } on FirebaseAuthException catch (e) {
      onError(e.message ?? 'Failed to send OTP.');
    } catch (_) {
      onError('Failed to send OTP.');
    }
  }

  Future<Map<String, dynamic>> verifyOTP({
    required String verificationId,
    required String otp,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      return _signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-verification-code') {
        return {'success': false, 'error': 'Wrong OTP. Please try again.'};
      }
      if (e.code == 'session-expired') {
        return {'success': false, 'error': 'OTP expired. Request a new OTP.'};
      }
      return {'success': false, 'error': e.message ?? 'Verification failed.'};
    } catch (_) {
      return {'success': false, 'error': 'Verification failed.'};
    }
  }

  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return {'success': false, 'error': 'Google sign-in was cancelled.'};
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return _signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'error': e.message ?? 'Google sign-in failed.'};
    } catch (e) {
      return {'success': false, 'error': 'Google sign-in failed.'};
    }
  }

  Future<Map<String, dynamic>> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user?.updateDisplayName(name);
      await credential.user?.reload();

      final refreshedUser = _auth.currentUser ?? credential.user;
      if (refreshedUser == null) {
        return {'success': false, 'error': 'Account creation failed.'};
      }

      final userModel = await _upsertUserDocument(
        firebaseUser: refreshedUser,
        isNewUser: true,
        fallbackName: name,
      );
      await _persistUser(userModel);

      return {'success': true, 'user': userModel, 'isNewUser': true};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'error': _mapEmailAuthError(e)};
    } catch (_) {
      return {'success': false, 'error': 'Unable to create account.'};
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.remove('token');
    await prefs.remove(StorageKeys.userId);
    await prefs.setBool(StorageKeys.isLoggedIn, false);
  }

  Future<Map<String, dynamic>> _signInWithCredential(
    AuthCredential credential,
  ) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        return {'success': false, 'error': 'Authentication failed.'};
      }

      final userModel = await _upsertUserDocument(
        firebaseUser: firebaseUser,
        isNewUser: userCredential.additionalUserInfo?.isNewUser ?? false,
      );
      await _persistUser(userModel);

      return {
        'success': true,
        'user': userModel,
        'isNewUser': userCredential.additionalUserInfo?.isNewUser ?? false,
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'error': e.message ?? 'Authentication failed.'};
    } catch (_) {
      return {'success': false, 'error': 'Authentication failed.'};
    }
  }

  Future<UserModel> _upsertUserDocument({
    required User firebaseUser,
    required bool isNewUser,
    String? fallbackName,
  }) async {
    final docRef = _firestore.collection('users').doc(firebaseUser.uid);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      final newUser = UserModel(
        uid: firebaseUser.uid,
        phone: firebaseUser.phoneNumber ?? '',
        email: firebaseUser.email,
        name: fallbackName ?? firebaseUser.displayName,
        avatar: firebaseUser.photoURL,
        isProfileComplete: false,
        isNewUser: isNewUser,
        token: await firebaseUser.getIdToken(),
        createdAt: DateTime.now(),
      );

      await docRef.set({
        ...newUser.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'loginCount': 1,
      });

      return newUser;
    }

    final data = snapshot.data() ?? <String, dynamic>{};
    final existingUser = UserModel.fromJson({
      ...data,
      'uid': data['uid'] ?? firebaseUser.uid,
      'phone': data['phone'] ?? firebaseUser.phoneNumber ?? '',
      'email': data['email'] ?? firebaseUser.email,
      'name': data['name'] ?? fallbackName ?? firebaseUser.displayName,
      'avatar': data['avatar'] ?? firebaseUser.photoURL,
      'token': await firebaseUser.getIdToken(),
      'createdAt': _serializeCreatedAt(data['createdAt']),
      'isNewUser': false,
    });

    await docRef.update({
      'email': existingUser.email,
      'name': existingUser.name,
      'avatar': existingUser.avatar,
      'phone': existingUser.phone,
      'lastLoginAt': FieldValue.serverTimestamp(),
      'loginCount': FieldValue.increment(1),
    });

    return existingUser;
  }

  Future<void> _persistUser(UserModel user) async {
    await _studentProfileService.resetProfileIfPhoneChanged(user.phone);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user.toJson()));
    await prefs.setString(StorageKeys.userId, user.uid);
    await prefs.setString('token', user.token ?? '');
    await prefs.setBool(StorageKeys.isLoggedIn, true);
    await prefs.setBool('isNewUser', user.isNewUser);
    await prefs.setBool(StorageKeys.profileComplete, user.isProfileComplete);
  }

  String _serializeCreatedAt(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    }
    if (value is DateTime) {
      return value.toIso8601String();
    }
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return DateTime.now().toIso8601String();
  }

  String _mapEmailAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      default:
        return e.message ?? 'Unable to create account.';
    }
  }
}
