import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum LegalDocumentType {
  termsOfService,
  privacyPolicy,
}

class LegalDocumentScreen extends StatelessWidget {
  final LegalDocumentType type;

  const LegalDocumentScreen({
    super.key,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sections = _sectionsFor(type);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          type == LegalDocumentType.termsOfService
              ? 'Terms of Service'
              : 'Privacy Policy',
          style:
              TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: Container(
        color: colors.background,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          itemBuilder: (context, index) {
            final section = sections[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  section.body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                        height: 1.55,
                      ),
                ),
              ],
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 18),
          itemCount: sections.length,
        ),
      ),
    );
  }

  List<_LegalSection> _sectionsFor(LegalDocumentType type) {
    if (type == LegalDocumentType.termsOfService) {
      return const [
        _LegalSection(
          title: 'Effective Date',
          body: 'February 10, 2026',
        ),
        _LegalSection(
          title: 'Use of the App',
          body:
              'Levio provides organization and education tools to support Parkinson\'s care routines. It does not replace medical advice, diagnosis, or treatment from licensed clinicians.',
        ),
        _LegalSection(
          title: 'Account Responsibilities',
          body:
              'You are responsible for keeping account access secure and for content you post in community areas. Harmful, abusive, or unsafe content may be removed.',
        ),
        _LegalSection(
          title: 'Health and Safety',
          body:
              'Exercise, speech, and recovery materials are educational only. Stop activities if you feel pain, dizziness, or distress, and contact your healthcare team.',
        ),
        _LegalSection(
          title: 'Content and Community',
          body:
              'You retain ownership of your submissions, and grant Levio permission to store and process them to provide app features. Community activity may be moderated for safety.',
        ),
        _LegalSection(
          title: 'Service Availability',
          body:
              'Features can change over time and may occasionally be unavailable for maintenance, updates, or third-party outages.',
        ),
      ];
    }

    return const [
      _LegalSection(
        title: 'Effective Date',
        body: 'February 10, 2026',
      ),
      _LegalSection(
        title: 'Data We Store',
        body:
            'Levio stores account profile data (name, email, user ID), symptom logs, medication schedules, and community posts/comments required for app functionality.',
      ),
      _LegalSection(
        title: 'How We Use Data',
        body:
            'Your data is used to deliver features such as tracking, reminders, charts, and community interactions. We do not sell your personal data.',
      ),
      _LegalSection(
        title: 'Cloud Processing',
        body:
            'Data is stored in Supabase-backed cloud services configured by the app operator. Access controls are enforced with authenticated access policies.',
      ),
      _LegalSection(
        title: 'Community Safety',
        body:
            'Posts and comments can be moderated to reduce harmful or unsafe content. Please avoid sharing private contact details or sensitive personal information in community posts.',
      ),
      _LegalSection(
        title: 'Your Controls',
        body:
            'You can update profile information and request account deletion from Settings. Deleting your account removes associated cloud data used by the app.',
      ),
    ];
  }
}

class _LegalSection {
  final String title;
  final String body;

  const _LegalSection({
    required this.title,
    required this.body,
  });
}
