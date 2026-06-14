import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class TestPackagesScreen extends StatelessWidget {
  const TestPackagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Test Series Packages', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
            Text('Unlock multiple tests at one price', style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: const Color(0xFF0D2240),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('testPackages')
            .where('isActive', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No test packages available at the moment.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final pkg = docs[index];
              final data = pkg.data() as Map<String, dynamic>;
              final pkgId = pkg.id;
              final testIds = List<String>.from(data['tests'] ?? []);

              return _buildPackageCard(context, pkgId, data, testIds, isDark);
            },
          );
        },
      ),
    );
  }

  Widget _buildPackageCard(
    BuildContext context,
    String pkgId,
    Map<String, dynamic> data,
    List<String> testIds,
    bool isDark,
  ) {
    final title = data['title'] ?? 'Test Package';
    final description = data['description'] ?? '';
    final badge = data['badge'] ?? '';
    final price = (data['price'] ?? 0).toDouble();
    final originalPrice = (data['originalPrice'] ?? 0).toDouble();
    final validityDays = data['validityDays'] ?? 365;

    final gradientColors = [const Color(0xFF0D2240), const Color(0xFF1D4ED8)];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Gradient Header
          Container(
            height: 90,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  top: -20,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white.withOpacity(0.05),
                  ),
                ),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('📝', style: TextStyle(fontSize: 36)),
                      const SizedBox(width: 12),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            testIds.length.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                          const Text(
                            'Tests Included',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF0D2240),
                        ),
                      ),
                    ),
                    if (badge.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          border: Border.all(color: Colors.amber),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Test list preview
                if (testIds.isNotEmpty)
                  FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('tests')
                        .where(FieldPath.documentId, whereIn: testIds.take(10).toList())
                        .get(),
                    builder: (context, testSnapshot) {
                      if (testSnapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(height: 20, child: LinearProgressIndicator());
                      }
                      final testDocs = testSnapshot.data?.docs ?? [];
                      final previewDocs = testDocs.take(3).toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...previewDocs.map((doc) {
                            final testData = doc.data() as Map<String, dynamic>;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_outline, color: Colors.green, size: 14),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      testData['title'] ?? 'Untitled Test',
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          if (testIds.length > 3)
                            Text(
                              '+${testIds.length - 3} more tests',
                              style: const TextStyle(
                                color: Color(0xFF0D2240),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      );
                    },
                  ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '₹${price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : const Color(0xFF0D2240),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '₹${originalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Valid for $validityDays days',
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        context.push(
                          '/checkout',
                          extra: {
                            'itemType': 'package',
                            'itemId': pkgId,
                            'itemTitle': title,
                            'originalPrice': price,
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: const Color(0xFF0D2240),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Buy Now',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
