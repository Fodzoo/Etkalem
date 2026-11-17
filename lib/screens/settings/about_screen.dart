import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          'About App',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: colors.background,
        foregroundColor: colors.onSurface,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/logoPng2.png',width: 280,),

              const SizedBox(height: 24),

              Text(
                'Etkalem',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'Stay connected, anytime.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.65),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 35),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colors.outline.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      context,
                      icon: Icons.info_outline,
                      title: 'App Name',
                      value: 'Etkalem',
                    ),

                    const Divider(height: 25),
                    _buildInfoRow(
                      context,
                      icon: Icons.verified_outlined,
                      title: 'Version',
                      value: '1.0.0',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 35),

              Text(
                'Made with Fady Hany',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, color: colors.primary, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(color: colors.onSurface.withValues(alpha: 0.65)),
        ),
      ],
    );
  }
}
