import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class MyPackagesScreen extends StatelessWidget {
  const MyPackagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view your packages')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Test Packages'),
        backgroundColor: const Color(0xFF0D2240),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('packagePurchases')
            .where('userId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final purchases = snapshot.data?.docs ?? [];
          if (purchases.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No purchased test packages.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.push('/test-packages'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: const Color(0xFF0D2240),
                    ),
                    child: const Text('Explore Packages'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: purchases.length,
            itemBuilder: (context, index) {
              final purchase = purchases[index];
              final data = purchase.data() as Map<String, dynamic>;
              final title = data['packageTitle'] ?? 'Test Package';
              final testIds = List<String>.from(data['testIds'] ?? []);
              final validTill = (data['validTill'] as Timestamp?)?.toDate();

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0D2240),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (validTill != null)
                        Text(
                          'Valid till: ${validTill.day}/${validTill.month}/${validTill.year}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Tests Included (${testIds.length}):',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      if (testIds.isNotEmpty)
                        FutureBuilder<QuerySnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('tests')
                              .where(FieldPath.documentId, whereIn: testIds.take(10).toList())
                              .get(),
                          builder: (context, testSnapshot) {
                            if (testSnapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: LinearProgressIndicator());
                            }
                            final testDocs = testSnapshot.data?.docs ?? [];
                            if (testDocs.isEmpty) {
                              return const Text('No tests found in this package.', style: TextStyle(color: Colors.grey));
                            }

                            return Column(
                              children: testDocs.map((doc) {
                                final testData = doc.data() as Map<String, dynamic>;
                                final testId = doc.id;
                                final isExpired = validTill != null && validTill.isBefore(DateTime.now());

                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.description_outlined, color: Color(0xFF0D2240)),
                                  title: Text(
                                    testData['title'] ?? 'Untitled Test',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text('${testData['questionsCount'] ?? 0} questions'),
                                  trailing: ElevatedButton(
                                    onPressed: isExpired
                                        ? null
                                        : () {
                                            context.push('/tests/attempt/$testId');
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber,
                                      foregroundColor: const Color(0xFF0D2240),
                                      shape: const StadiumBorder(),
                                    ),
                                    child: const Text('Start Test'),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
