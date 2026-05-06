import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: cs.surfaceVariant,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),

            // App icon
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.construction,
                  size: 52, color: cs.onPrimaryContainer),
            ),
            const SizedBox(height: 16),

            Text('NetKit',
                style: textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('v1.0.0',
                style: textTheme.bodySmall
                    ?.copyWith(color: cs.onSurface.withOpacity(0.5))),
            const SizedBox(height: 8),
            Text(
              'Swiss Army Knife for free internet access.\nBuilt for Iranian users.',
              textAlign: TextAlign.center,
              style:
              textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // Features list
            _SectionTitle('Features', cs),
            const SizedBox(height: 12),
            ...[
              (Icons.code, 'Encoder / Decoder',
              'Base64, URL, HEX, MD5, SHA256'),
              (Icons.qr_code_2, 'QR Code Generator',
              'Create, save to gallery, share'),
              (Icons.network_ping, 'Site Ping Checker',
              'Check which sites are reachable'),
              (Icons.vpn_key, 'Proxy Manager',
              'MTProto & SOCKS5, open in Telegram'),
              (Icons.location_on, 'My IP',
              'Check your current IP & VPN status'),
            ].map(
                  (e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child:
                      Icon(e.$1, size: 20, color: cs.onPrimaryContainer),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.$2,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                          Text(e.$3,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurface.withOpacity(0.6))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Developer / links
            _SectionTitle('Developer', cs),
            const SizedBox(height: 12),

            _LinkCard(
              icon: Icons.code_rounded,
              title: 'GitHub',
              subtitle: 'github.com/mehdirzfx',
              onTap: () =>
                  _openUrl(context, 'https://github.com/mehdirzfx'),
              cs: cs,
            ),

            const SizedBox(height: 32),

            Text(
              'Made with ❤️ for free internet',
              style: textTheme.bodySmall
                  ?.copyWith(color: cs.onSurface.withOpacity(0.4)),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final ColorScheme cs;
  const _SectionTitle(this.text, this.cs);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: cs.primary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _LinkCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final ColorScheme cs;

  const _LinkCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: cs.primary, size: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style:
                        const TextStyle(fontWeight: FontWeight.w600)),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withOpacity(0.6))),
                  ],
                ),
              ),
              Icon(Icons.open_in_new, size: 18, color: cs.outline),
            ],
          ),
        ),
      ),
    );
  }
}