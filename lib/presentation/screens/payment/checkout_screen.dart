import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

class CheckoutScreen extends StatefulWidget {
  final String itemType;
  final String itemId;
  final String itemTitle;
  final double originalPrice;
  final String? courseId;

  const CheckoutScreen({
    super.key,
    required this.itemType,
    required this.itemId,
    required this.itemTitle,
    required this.originalPrice,
    this.courseId,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _promoController = TextEditingController();
  final _upiTxnController = TextEditingController();
  File? _screenshotFile;
  bool _promoApplied = false;
  bool _isCheckingPromo = false;
  bool _isProcessing = false;
  String? _promoError;
  String? _appliedPromoId;
  String? _appliedPromoCode;
  late double _finalAmount;
  Map<String, dynamic>? _paymentSettings;

  @override
  void initState() {
    super.initState();
    _finalAmount = widget.originalPrice;
    _loadPaymentSettings();
  }

  @override
  void dispose() {
    _promoController.dispose();
    _upiTxnController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentSettings() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('site_settings')
          .get();
      if (mounted && doc.exists) {
        setState(() {
          _paymentSettings = doc.data()?['paymentSettings'] as Map<String, dynamic>?;
        });
      }
    } catch (_) {}
  }

  Future<void> _applyPromoCode() async {
    final code = _promoController.text.trim().toUpperCase();

    if (code.isEmpty) {
      setState(() => _promoError = 'Please enter a promo code');
      return;
    }

    setState(() {
      _isCheckingPromo = true;
      _promoError = null;
    });

    try {
      final query = await FirebaseFirestore.instance
          .collection('promoCodes')
          .where('code', isEqualTo: code)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        setState(() {
          _isCheckingPromo = false;
          _promoError = '❌ Invalid promo code. Please check and try again.';
        });
        return;
      }

      final promoDoc = query.docs.first;
      final promoData = promoDoc.data();
      final promoId = promoDoc.id;

      final validTill = (promoData['validTill'] as Timestamp?)?.toDate();
      if (validTill != null && validTill.isBefore(DateTime.now())) {
        setState(() {
          _isCheckingPromo = false;
          _promoError = '⏰ This promo code has expired.';
        });
        return;
      }

      final maxUses = promoData['maxUses'] as int? ?? 0;
      final usedCount = promoData['usedCount'] as int? ?? 0;
      if (maxUses > 0 && usedCount >= maxUses) {
        setState(() {
          _isCheckingPromo = false;
          _promoError = '😔 This promo code has reached its usage limit.';
        });
        return;
      }

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final usedBy = (promoData['usedBy'] as List?) ?? [];
        if (usedBy.contains(uid)) {
          setState(() {
            _isCheckingPromo = false;
            _promoError = '🚫 You have already used this promo code.';
          });
          return;
        }
      }

      final applicableTo = promoData['applicableTo'] as String? ?? 'all';
      final itemType = widget.itemType;

      bool isApplicable = applicableTo == 'all' ||
          (applicableTo == 'courses' && itemType == 'course') ||
          (applicableTo == 'tests' && itemType == 'test') ||
          (applicableTo == 'packages' && itemType == 'package');

      if (!isApplicable) {
        setState(() {
          _isCheckingPromo = false;
          _promoError = '🚫 This code is not valid for this type of purchase.';
        });
        return;
      }

      setState(() {
        _isCheckingPromo = false;
        _promoApplied = true;
        _promoError = null;
        _appliedPromoId = promoId;
        _appliedPromoCode = code;
        _finalAmount = 0;
      });
    } catch (e) {
      setState(() {
        _isCheckingPromo = false;
        _promoError = 'Error checking code. Please try again.';
      });
    }
  }

  void _removePromo() {
    setState(() {
      _promoApplied = false;
      _promoError = null;
      _appliedPromoId = null;
      _appliedPromoCode = null;
      _finalAmount = widget.originalPrice;
      _promoController.clear();
    });
  }

  Future<void> _pickScreenshot() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (picked != null) {
        final cropped = await ImageCropper().cropImage(
          sourcePath: picked.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Screenshot',
              toolbarColor: const Color(0xFF0D2240),
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
            ),
          ],
        );
        if (cropped != null) {
          setState(() => _screenshotFile = File(cropped.path));
        } else {
          setState(() => _screenshotFile = File(picked.path));
        }
      }
    } catch (_) {}
  }

  Future<void> _confirmPurchase() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (_finalAmount > 0) {
      final hasTxnId = _upiTxnController.text.trim().isNotEmpty;
      final hasScreenshot = _screenshotFile != null;

      if (!hasTxnId && !hasScreenshot) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter UPI transaction ID or upload payment screenshot'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isProcessing = true);

    try {
      String? screenshotUrl;

      if (_screenshotFile != null && _finalAmount > 0) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('payment_screenshots')
            .child('${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');

        await storageRef.putFile(_screenshotFile!);
        screenshotUrl = await storageRef.getDownloadURL();
      }

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final userData = userDoc.data() ?? {};

      if (_finalAmount == 0) {
        await _processFreeEnrollment(uid);
      } else {
        await _createPendingOrder(uid, userData, screenshotUrl);
      }

      if (_appliedPromoId != null) {
        await FirebaseFirestore.instance.collection('promoCodes').doc(_appliedPromoId!).update({
          'usedCount': FieldValue.increment(1),
          'usedBy': FieldValue.arrayUnion([uid]),
        });
      }

      setState(() => _isProcessing = false);

      if (_finalAmount == 0) {
        context.go('/enrollment-success', extra: {
          'itemTitle': widget.itemTitle,
          'isFree': true,
          'itemId': widget.itemId,
          'itemType': widget.itemType,
        });
      } else {
        context.go('/payment-pending', extra: {
          'itemTitle': widget.itemTitle,
          'amount': _finalAmount,
        });
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _processFreeEnrollment(String uid) async {
    final batch = FirebaseFirestore.instance.batch();

    if (widget.itemType == 'course') {
      batch.set(
        FirebaseFirestore.instance.collection('enrollments').doc('${uid}_${widget.itemId}'),
        {
          'userId': uid,
          'courseId': widget.itemId,
          'courseTitle': widget.itemTitle,
          'enrolledAt': FieldValue.serverTimestamp(),
          'progress': 0,
          'completedVideos': [],
          'isCompleted': false,
          'paymentAmount': 0,
          'promoCodeUsed': _appliedPromoCode,
        },
      );

      batch.update(
        FirebaseFirestore.instance.collection('users').doc(uid),
        {
          'enrolledCourses': FieldValue.arrayUnion([widget.itemId]),
          'xp': FieldValue.increment(50),
        },
      );

      batch.update(
        FirebaseFirestore.instance.collection('courses').doc(widget.itemId),
        {'totalEnrollments': FieldValue.increment(1)},
      );
    }

    if (widget.itemType == 'package') {
      final pkgDoc = await FirebaseFirestore.instance.collection('testPackages').doc(widget.itemId).get();

      batch.set(
        FirebaseFirestore.instance.collection('packagePurchases').doc('${uid}_${widget.itemId}'),
        {
          'userId': uid,
          'packageId': widget.itemId,
          'packageTitle': widget.itemTitle,
          'testIds': pkgDoc.data()?['tests'] ?? [],
          'purchasedAt': FieldValue.serverTimestamp(),
          'paymentAmount': 0,
          'promoCodeUsed': _appliedPromoCode,
          'validTill': Timestamp.fromDate(
            DateTime.now().add(Duration(days: pkgDoc.data()?['validityDays'] ?? 365)),
          ),
        },
      );

      batch.update(
        FirebaseFirestore.instance.collection('testPackages').doc(widget.itemId),
        {'totalPurchases': FieldValue.increment(1)},
      );
    }

    final newOrderRef = FirebaseFirestore.instance.collection('orders').doc();
    batch.set(
      newOrderRef,
      {
        'userId': uid,
        'itemType': widget.itemType,
        'itemId': widget.itemId,
        'itemTitle': widget.itemTitle,
        'originalAmount': widget.originalPrice,
        'finalAmount': 0,
        'promoCodeUsed': _appliedPromoCode,
        'paymentStatus': 'free',
        'paymentMethod': 'promo_free',
        'createdAt': FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
  }

  Future<void> _createPendingOrder(
    String uid,
    Map<String, dynamic> userData,
    String? screenshotUrl,
  ) async {
    await FirebaseFirestore.instance.collection('orders').add({
      'userId': uid,
      'userName': userData['name'] ?? '',
      'userPhone': userData['phone'] ?? '',
      'itemType': widget.itemType,
      'itemId': widget.itemId,
      'itemTitle': widget.itemTitle,
      'originalAmount': widget.originalPrice,
      'finalAmount': _finalAmount,
      'promoCodeUsed': _appliedPromoCode,
      'paymentStatus': 'pending_verification',
      'paymentMethod': 'upi_manual',
      'upiTransactionId': _upiTxnController.text.trim(),
      'paymentScreenshotUrl': screenshotUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': uid,
      'target': uid,
      'title': '⏳ Payment Under Review',
      'body': 'Your payment for "${widget.itemTitle}" is being verified. Access will be granted within 2 hours.',
      'type': 'payment',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: const Color(0xFF0D2240),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // SECTION 1 — ITEM SUMMARY CARD
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0D2240), Color(0xFF2563EB)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Text(
                            '📚',
                            style: TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.itemType == 'course' ? 'COURSE' : 'TEST PACKAGE',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.itemTitle,
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF0D2240),
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text(
                        'Original Price',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const Spacer(),
                      Text(
                        '₹${widget.originalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Color(0xFF888888),
                          fontSize: 14,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // SECTION 2 — PROMO CODE
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Have a Promo Code?',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0D2240),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _promoController,
                          textCapitalization: TextCapitalization.characters,
                          onChanged: (_) {
                            if (_promoError != null || _promoApplied) {
                              setState(() {
                                _promoError = null;
                                _promoApplied = false;
                                _appliedPromoCode = null;
                                _appliedPromoId = null;
                                _finalAmount = widget.originalPrice;
                              });
                            }
                          },
                          decoration: InputDecoration(
                            hintText: 'Enter promo code',
                            prefixIcon: const Icon(Icons.confirmation_num_outlined, color: Colors.amber),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF9FAFB),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 52,
                        width: 90,
                        child: ElevatedButton(
                          onPressed: _isCheckingPromo ? null : _applyPromoCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D2240),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isCheckingPromo
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _promoApplied
                        ? Container(
                            key: const ValueKey('applied'),
                            margin: const EdgeInsets.only(top: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              border: Border.all(color: Colors.green),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '🎉 Promo Applied!',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        'This purchase is now FREE!',
                                        style: TextStyle(color: Colors.green, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.green),
                                  onPressed: _removePromo,
                                )
                              ],
                            ),
                          )
                        : _promoError != null
                            ? Container(
                                key: const ValueKey('error'),
                                margin: const EdgeInsets.only(top: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  border: Border.all(color: Colors.red),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: Colors.red, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _promoError!,
                                        style: const TextStyle(color: Colors.red, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // SECTION 3 — PRICE SUMMARY
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Summary',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0D2240),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Price', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      const Spacer(),
                      Text('₹${widget.originalPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                  if (_promoApplied) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Text('Promo Discount', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        const Spacer(),
                        Text('-₹${widget.originalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        'Total Amount',
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF0D2240),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _promoApplied ? '₹0 FREE!' : '₹${_finalAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: _promoApplied ? Colors.green : const Color(0xFF0D2240),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // SECTION 4 — PAYMENT METHOD
            if (_finalAmount > 0) ...[
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pay via UPI',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0D2240),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_paymentSettings != null) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (_paymentSettings!['qrImageUrl'] != null &&
                              (_paymentSettings!['qrImageUrl'] as String).isNotEmpty)
                            Center(
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: borderColor),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: Image.network(
                                  _paymentSettings!['qrImageUrl'] as String,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(child: Icon(Icons.qr_code, size: 80, color: Colors.grey));
                                  },
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          if (_paymentSettings!['upiId'] != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('UPI ID', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                        Text(
                                          _paymentSettings!['upiId'] as String,
                                          style: const TextStyle(
                                            color: Color(0xFF0D2240),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Clipboard.setData(
                                        ClipboardData(text: _paymentSettings!['upiId'] as String),
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('UPI ID Copied!')),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber,
                                      foregroundColor: const Color(0xFF0D2240),
                                      shape: const StadiumBorder(),
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      elevation: 0,
                                    ),
                                    child: const Text('Copy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 12),
                          if (_paymentSettings!['instructions'] != null)
                            Text(
                              _paymentSettings!['instructions'] as String,
                              style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.6),
                              textAlign: TextAlign.center,
                            ),
                          const SizedBox(height: 16),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'After paying, enter your UPI Transaction ID',
                              style: TextStyle(
                                color: Color(0xFF0D2240),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _upiTxnController,
                            decoration: InputDecoration(
                              hintText: 'e.g. UPI123456789',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Center(child: Text('OR', style: TextStyle(color: Colors.grey))),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _pickScreenshot,
                            child: Container(
                              height: 100,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey,
                                  style: BorderStyle.values[0], // Dashed border simulated using standard custom styling
                                ),
                                borderRadius: BorderRadius.circular(12),
                                color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF9FAFB),
                              ),
                              child: _screenshotFile != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        _screenshotFile!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      ),
                                    )
                                  : const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.upload_file, color: Colors.grey, size: 32),
                                        Text('Upload Payment Screenshot', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                        Text('(tap to select)', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ] else
                      const Center(child: CircularProgressIndicator()),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // SECTION 5 — CONFIRM BUTTON
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _confirmPurchase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: const Color(0xFF0D2240),
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                child: _isProcessing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Color(0xFF0D2240)),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Processing...',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          )
                        ],
                      )
                    : Text(
                        _finalAmount == 0 ? '✅ Confirm Free Enrollment' : '📤 Submit Payment for Verification',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
