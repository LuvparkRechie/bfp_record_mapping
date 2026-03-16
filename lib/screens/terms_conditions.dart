import 'package:flutter/material.dart';

class BFPTermsDialog extends StatelessWidget {
  final Function(bool accepted) onAccept;

  const BFPTermsDialog({Key? key, required this.onAccept}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: 800,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height,
        ),
        child: Column(
          children: [
            // Header with BFP styling
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.gavel,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BFP Record Mapping',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Terms and Conditions',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'v1.0',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Terms content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      '1. Data Collection',
                      Icons.data_usage,
                      'By using this application, you consent to the collection and mapping of inspection records, establishment data, and compliance information as part of the Bureau of Fire Protection (BFP) record management system.',
                    ),
                    _buildSection(
                      '2. Data Accuracy',
                      Icons.verified,
                      'You are responsible for ensuring that all information entered into the system is accurate, complete, and up-to-date. The BFP reserves the right to verify any information provided.',
                    ),
                    _buildSection(
                      '3. Confidentiality',
                      Icons.lock,
                      'All inspection records and establishment data are confidential and shall only be accessed by authorized BFP personnel. Unauthorized disclosure of information is strictly prohibited.',
                    ),
                    _buildSection(
                      '4. Data Usage',
                      Icons.analytics,
                      'Collected data may be used for statistical analysis, compliance monitoring, and improving fire safety standards. Anonymized data may be used for research purposes.',
                    ),
                    _buildSection(
                      '5. Record Retention',
                      Icons.storage,
                      'Inspection records shall be retained in accordance with BFP data retention policies. You may request access to your records subject to existing rules and regulations.',
                    ),
                    _buildSection(
                      '6. User Responsibilities',
                      Icons.person,
                      'You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account.',
                    ),
                    _buildSection(
                      '7. Compliance',
                      Icons.gpp_good,
                      'You agree to comply with all applicable laws, rules, and regulations of the Bureau of Fire Protection and the Republic of the Philippines.',
                    ),
                    _buildSection(
                      '8. Modifications',
                      Icons.edit,
                      'The BFP reserves the right to modify these terms and conditions at any time. Continued use of the system constitutes acceptance of modified terms.',
                    ),

                    const SizedBox(height: 16),

                    // Acknowledgment
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.red.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'By accepting these terms, you acknowledge that you have read, understood, and agree to be bound by these terms and conditions.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.red.shade800,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer with buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        onAccept(false);
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('DECLINE'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        onAccept(true);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('ACCEPT'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: Colors.red.shade700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Usage
void showBFPTermsDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false, // Prevent accidental dismissal
    builder: (context) => BFPTermsDialog(
      onAccept: (accepted) {
        if (accepted) {
          // Handle accept
          print('Terms accepted');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Terms and conditions accepted'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Handle decline
          print('Terms declined');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You must accept the terms to continue'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    ),
  );
}
