import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;

enum SiteStatus { unknown, checking, online, offline }

class SiteItem {
  String name;
  String url;
  bool isCustom;
  SiteStatus status;
  int? responseTimeMs;
  int? statusCode;

  SiteItem({
    required this.name,
    required this.url,
    this.isCustom = false,
    this.status = SiteStatus.unknown,
    this.responseTimeMs,
    this.statusCode,
  });
}

class PingScreen extends StatefulWidget {
  const PingScreen({super.key});

  @override
  State<PingScreen> createState() => _PingScreenState();
}

class _PingScreenState extends State<PingScreen> {
  final TextEditingController _urlCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  bool _isCheckingAll = false;

  final List<SiteItem> _sites = [
    SiteItem(name: 'Google', url: 'https://www.google.com'),
    SiteItem(name: 'YouTube', url: 'https://www.youtube.com'),
    SiteItem(name: 'GitHub', url: 'https://github.com'),
    SiteItem(name: 'ChatGPT',url: 'https://chatgpt.com'),
    SiteItem(name: 'DeepSeek',url: 'https://deepseek.com'),
    SiteItem(name: 'Telegram', url: 'https://web.telegram.org'),
    SiteItem(name: 'Twitter / X', url: 'https://twitter.com'),
    SiteItem(name: 'Instagram', url: 'https://www.instagram.com'),
    SiteItem(name: 'WhatsApp', url: 'https://web.whatsapp.com'),
    SiteItem(name: 'Spotify', url: 'https://open.spotify.com'),
    SiteItem(name: 'Pinterest', url: 'https://www.pinterest.com'),
    SiteItem(name: 'LinkedIn', url: 'https://www.linkedin.com'),
    SiteItem(name: 'Reddit', url: 'https://www.reddit.com'),
    SiteItem(name: 'Wikipedia', url: 'https://www.wikipedia.org'),
    SiteItem(name: 'Divar', url: 'https://divar.ir'),
    SiteItem(name: 'Digikala', url: 'https://www.digikala.com'),
    SiteItem(name: 'Varzesh3', url: 'https://www.varzesh3.com'),
    SiteItem(name: 'Cloudflare', url: 'https://1.1.1.1'),
  ];

  Future<void> _checkSite(SiteItem site) async {
    setState(() {
      site.status = SiteStatus.checking;
      site.responseTimeMs = null;
      site.statusCode = null;
    });
    try {
      final sw = Stopwatch()..start();
      final res = await http
          .get(Uri.parse(site.url))
          .timeout(const Duration(seconds: 8));
      sw.stop();
      setState(() {
        site.status =
            res.statusCode < 500 ? SiteStatus.online : SiteStatus.offline;
        site.responseTimeMs = sw.elapsedMilliseconds;
        site.statusCode = res.statusCode;
      });
    } catch (_) {
      setState(() {
        site.status = SiteStatus.offline;
        site.responseTimeMs = null;
      });
    }
  }

  Future<void> _checkAll() async {
    setState(() => _isCheckingAll = true);
    await Future.wait(_sites.map(_checkSite));
    setState(() => _isCheckingAll = false);
  }

  void _showAddDialog() {
    _nameCtrl.clear();
    _urlCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Site'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlCtrl,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'URL (e.g. https://example.com)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final name = _nameCtrl.text.trim();
              var url = _urlCtrl.text.trim();
              if (name.isEmpty || url.isEmpty) return;
              if (!url.startsWith('http')) url = 'https://$url';
              setState(() => _sites.add(
                    SiteItem(name: name, url: url, isCustom: true),
                  ));
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(SiteStatus s, ColorScheme cs) {
    switch (s) {
      case SiteStatus.online:
        return Colors.green;
      case SiteStatus.offline:
        return cs.error;
      case SiteStatus.checking:
        return Colors.orange;
      case SiteStatus.unknown:
        return cs.outline;
    }
  }

  IconData _statusIcon(SiteStatus s) {
    switch (s) {
      case SiteStatus.online:
        return Icons.check_circle;
      case SiteStatus.offline:
        return Icons.cancel;
      case SiteStatus.checking:
        return Icons.hourglass_top;
      case SiteStatus.unknown:
        return Icons.circle_outlined;
    }
  }

  String _statusLabel(SiteItem site) {
    switch (site.status) {
      case SiteStatus.online:
        return site.responseTimeMs != null
            ? '${site.responseTimeMs}ms'
            : 'Online';
      case SiteStatus.offline:
        return 'Offline';
      case SiteStatus.checking:
        return 'Checking...';
      case SiteStatus.unknown:
        return '—';
    }
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onlineCount =
        _sites.where((s) => s.status == SiteStatus.online).length;
    final offlineCount =
        _sites.where((s) => s.status == SiteStatus.offline).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Site Ping Checker'),
        backgroundColor: cs.surfaceVariant,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add site',
            onPressed: _showAddDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: cs.surfaceVariant,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatBadge(label: 'Online', count: onlineCount, color: Colors.green),
                _StatBadge(label: 'Offline', count: offlineCount, color: cs.error),
                _StatBadge(label: 'Total', count: _sites.length, color: cs.primary),
                FilledButton.icon(
                  onPressed: _isCheckingAll ? null : _checkAll,
                  icon: _isCheckingAll
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_tethering, size: 18),
                  label: Text(_isCheckingAll ? 'Checking...' : 'Check All'),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _sites.length,
              itemBuilder: (ctx, i) {
                final site = _sites[i];
                final color = _statusColor(site.status, cs);

                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    leading: Icon(_statusIcon(site.status),
                        color: color, size: 28),
                    title: Text(site.name,
                        style:
                            const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      site.url,
                      style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withOpacity(0.55)),
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.ltr,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _statusLabel(site),
                            style: TextStyle(
                                color: color,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 20),
                          onPressed: site.status == SiteStatus.checking
                              ? null
                              : () => _checkSite(site),
                        ),
                        if (site.isCustom)
                          IconButton(
                            icon: Icon(Icons.delete_outline,
                                size: 20, color: cs.error),
                            onPressed: () =>
                                setState(() => _sites.remove(site)),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatBadge(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(count.toString(),
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}
