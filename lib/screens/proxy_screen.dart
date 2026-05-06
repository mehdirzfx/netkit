import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:io';

enum ProxyType { mtproto, socks5 }

enum ProxyStatus { unknown, checking, ok, failed }

class ProxyItem {
  final String id;
  String server;
  int port;
  String secret;
  String username;
  String password;
  ProxyType type;
  ProxyStatus status;
  int? pingMs;
  String? note;

  ProxyItem({
    required this.id,
    required this.server,
    required this.port,
    this.secret = '',
    this.username = '',
    this.password = '',
    required this.type,
    this.status = ProxyStatus.unknown,
    this.pingMs,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'server': server,
    'port': port,
    'secret': secret,
    'username': username,
    'password': password,
    'type': type.name,
    'note': note,
  };

  factory ProxyItem.fromJson(Map<String, dynamic> j) => ProxyItem(
    id: j['id'],
    server: j['server'],
    port: j['port'],
    secret: j['secret'] ?? '',
    username: j['username'] ?? '',
    password: j['password'] ?? '',
    type: j['type'] == 'socks5' ? ProxyType.socks5 : ProxyType.mtproto,
    note: j['note'],
  );

  String get httpsLink {
    if (type == ProxyType.mtproto) {
      return 'https://t.me/proxy?server=$server&port=$port&secret=$secret';
    } else {
      var link = 'https://t.me/socks?server=$server&port=$port';
      if (username.isNotEmpty) link += '&user=$username';
      if (password.isNotEmpty) link += '&pass=$password';
      return link;
    }
  }

  String get tgLink {
    if (type == ProxyType.mtproto) {
      return 'tg://proxy?server=$server&port=$port&secret=$secret';
    } else {
      var link = 'tg://socks?server=$server&port=$port';
      if (username.isNotEmpty) link += '&user=$username';
      if (password.isNotEmpty) link += '&pass=$password';
      return link;
    }
  }
}

// Parser

ProxyItem? parseProxyFromText(String raw) {
  raw = raw.trim();
  if (raw.isEmpty) return null;
  final id = DateTime.now().millisecondsSinceEpoch.toString();

  if (raw.startsWith('tg://') || raw.startsWith('https://t.me/')) {
    try {
      final normalised = raw.startsWith('tg://')
          ? raw.replaceFirst('tg://', 'https://tg/')
          : raw;
      final uri = Uri.parse(normalised);
      final p = uri.queryParameters;
      final isSocks = uri.path.contains('socks') || uri.host == 'socks';

      return ProxyItem(
        id: id,
        server: p['server'] ?? '',
        port: int.tryParse(p['port'] ?? '') ?? (isSocks ? 1080 : 443),
        secret: p['secret'] ?? '',
        username: p['user'] ?? '',
        password: p['pass'] ?? '',
        type: isSocks ? ProxyType.socks5 : ProxyType.mtproto,
      );
    } catch (_) {
      return null;
    }
  }

  final ipPort = RegExp(r'^([\w.\-]+):(\d{1,5})$');
  final m = ipPort.firstMatch(raw);
  if (m != null) {
    return ProxyItem(
      id: id,
      server: m.group(1)!,
      port: int.parse(m.group(2)!),
      type: ProxyType.mtproto,
      note: 'Imported (ip:port)',
    );
  }

  return null;
}

// Screen

class ProxyScreen extends StatefulWidget {
  const ProxyScreen({super.key});

  @override
  State<ProxyScreen> createState() => _ProxyScreenState();
}

class _ProxyScreenState extends State<ProxyScreen> {
  List<ProxyItem> _proxies = [];
  bool _isCheckingAll = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // persistence

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('proxies_v2');
    if (data != null) {
      final list = jsonDecode(data) as List;
      setState(() =>
      _proxies = list.map((j) => ProxyItem.fromJson(j)).toList());
    } else {
      setState(() {
        _proxies = [
          ProxyItem(
            id: 'demo1',
            server: 'proxy.example.com',
            port: 443,
            secret: 'dd000000000000000000000000000000',
            type: ProxyType.mtproto,
            note: 'Demo MTProto',
          ),
          ProxyItem(
            id: 'demo2',
            server: '1.2.3.4',
            port: 1080,
            type: ProxyType.socks5,
            note: 'Demo SOCKS5',
          ),
        ];
      });
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'proxies_v2', jsonEncode(_proxies.map((p) => p.toJson()).toList()));
  }

  // ── ping ───────────────────────────────────────────────────────────────────

  Future<void> _ping(ProxyItem proxy) async {
    setState(() {
      proxy.status = ProxyStatus.checking;
      proxy.pingMs = null;
    });
    try {
      final sw = Stopwatch()..start();
      final sock = await Socket.connect(proxy.server, proxy.port,
          timeout: const Duration(seconds: 8));
      sw.stop();
      sock.destroy();
      setState(() {
        proxy.status = ProxyStatus.ok;
        proxy.pingMs = sw.elapsedMilliseconds;
      });
    } catch (_) {
      setState(() => proxy.status = ProxyStatus.failed);
    }
  }

  Future<void> _pingAll() async {
    if (_proxies.isEmpty) return;
    setState(() => _isCheckingAll = true);
    await Future.wait(_proxies.map(_ping));
    setState(() => _isCheckingAll = false);
  }

  // ── open in Telegram (fixed) ───────────────────────────────────────────────

  Future<void> _openInTelegram(ProxyItem proxy) async {
    final tgUri = Uri.parse(proxy.tgLink);
    try {
      await launchUrl(tgUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(
          Uri.parse(proxy.httpsLink),
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open Telegram')),
          );
        }
      }
    }
  }

  // copy

  void _copyLink(ProxyItem proxy) {
    Clipboard.setData(ClipboardData(text: proxy.httpsLink));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Link copied!'), duration: Duration(seconds: 1)),
    );
  }

  // import dialog

  void _showImport() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Proxy'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Supported formats:',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              '• tg://proxy?server=…&port=…&secret=…\n'
                  '• tg://socks?server=…&port=…\n'
                  '• https://t.me/proxy?…\n'
                  '• https://t.me/socks?…\n'
                  '• ip:port',
              style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              textDirection: TextDirection.ltr,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Paste link or ip:port here…',
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
              final proxy = parseProxyFromText(ctrl.text);
              Navigator.pop(ctx);
              if (proxy != null && proxy.server.isNotEmpty) {
                setState(() => _proxies.add(proxy));
                _save();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Proxy imported!')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not parse proxy')),
                );
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  // manual add dialog

  void _showAdd() {
    final formKey = GlobalKey<FormState>();
    ProxyType selType = ProxyType.mtproto;
    final serverCtrl = TextEditingController();
    final portCtrl = TextEditingController(text: '443');
    final secretCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          title: const Text('Add Proxy'),
          scrollable: true,
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<ProxyType>(
                  segments: const [
                    ButtonSegment(
                        value: ProxyType.mtproto,
                        label: Text('MTProto'),
                        icon: Icon(Icons.shield, size: 16)),
                    ButtonSegment(
                        value: ProxyType.socks5,
                        label: Text('SOCKS5'),
                        icon: Icon(Icons.swap_horiz, size: 16)),
                  ],
                  selected: {selType},
                  onSelectionChanged: (s) => setDs(() => selType = s.first),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: serverCtrl,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                      labelText: 'Server', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: portCtrl,
                  textDirection: TextDirection.ltr,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Port', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                if (selType == ProxyType.mtproto)
                  TextFormField(
                    controller: secretCtrl,
                    textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(
                        labelText: 'Secret (optional)',
                        border: OutlineInputBorder()),
                  )
                else ...[
                  TextFormField(
                    controller: userCtrl,
                    textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(
                        labelText: 'Username (optional)',
                        border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: passCtrl,
                    textDirection: TextDirection.ltr,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'Password (optional)',
                        border: OutlineInputBorder()),
                  ),
                ],
                const SizedBox(height: 8),
                TextFormField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Label (optional)',
                      border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                setState(() => _proxies.add(ProxyItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  server: serverCtrl.text.trim(),
                  port: int.tryParse(portCtrl.text) ?? 443,
                  secret: secretCtrl.text.trim(),
                  username: userCtrl.text.trim(),
                  password: passCtrl.text.trim(),
                  type: selType,
                  note: noteCtrl.text.trim().isEmpty
                      ? null
                      : noteCtrl.text.trim(),
                )));
                _save();
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  // helpers

  Color _statusColor(ProxyStatus s, ColorScheme cs) => switch (s) {
    ProxyStatus.ok => Colors.green,
    ProxyStatus.failed => cs.error,
    ProxyStatus.checking => Colors.orange,
    ProxyStatus.unknown => cs.outline,
  };

  String _pingLabel(ProxyItem p) => switch (p.status) {
    ProxyStatus.ok => p.pingMs != null ? '${p.pingMs}ms' : 'OK',
    ProxyStatus.failed => 'Down',
    ProxyStatus.checking => '…',
    ProxyStatus.unknown => '—',
  };

  // build

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final okCount = _proxies.where((p) => p.status == ProxyStatus.ok).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Proxy Manager'),
        backgroundColor: cs.surfaceVariant,
        actions: [
          IconButton(
            icon: const Icon(Icons.link),
            tooltip: 'Import',
            onPressed: _showImport,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add manually',
            onPressed: _showAdd,
          ),
        ],
      ),
      body: Column(
        children: [
          // summary bar
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: cs.surfaceVariant,
            child: Row(
              children: [
                Text(
                  '$okCount / ${_proxies.length} active',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed:
                  _isCheckingAll || _proxies.isEmpty ? null : _pingAll,
                  icon: _isCheckingAll
                      ? const SizedBox(
                      width: 16,
                      height: 16,
                      child:
                      CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.speed, size: 18),
                  label: Text(_isCheckingAll ? 'Pinging…' : 'Ping All'),
                ),
              ],
            ),
          ),

          // list
          Expanded(
            child: _proxies.isEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.vpn_key_off,
                      size: 56, color: cs.outline),
                  const SizedBox(height: 12),
                  Text('No proxies yet.',
                      style: TextStyle(color: cs.outline)),
                ],
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _proxies.length,
              separatorBuilder: (_, __) =>
              const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final proxy = _proxies[i];
                final color = _statusColor(proxy.status, cs);
                final isMtp = proxy.type == ProxyType.mtproto;

                return Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding:
                    const EdgeInsets.fromLTRB(14, 10, 4, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // row 1: type + label + ping badge
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: isMtp
                                    ? cs.primaryContainer
                                    : cs.secondaryContainer,
                                borderRadius:
                                BorderRadius.circular(6),
                              ),
                              child: Text(
                                isMtp ? 'MTProto' : 'SOCKS5',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isMtp
                                      ? cs.onPrimaryContainer
                                      : cs.onSecondaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (proxy.note != null)
                              Expanded(
                                child: Text(proxy.note!,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14),
                                    overflow:
                                    TextOverflow.ellipsis),
                              )
                            else
                              const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                borderRadius:
                                BorderRadius.circular(6),
                              ),
                              child: Text(
                                _pingLabel(proxy),
                                style: TextStyle(
                                    color: color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        //  row 2: server:port
                        Text(
                          '${proxy.server}:${proxy.port}',
                          style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: cs.onSurface.withOpacity(0.75)),
                          textDirection: TextDirection.ltr,
                        ),

                        // row 3: actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _ActionBtn(
                              icon: Icons.refresh,
                              label: 'Ping',
                              onPressed: proxy.status ==
                                  ProxyStatus.checking
                                  ? null
                                  : () => _ping(proxy),
                            ),
                            _ActionBtn(
                              icon: Icons.send,
                              label: 'Open',
                              color: cs.primary,
                              onPressed: () =>
                                  _openInTelegram(proxy),
                            ),
                            _ActionBtn(
                              icon: Icons.copy,
                              label: 'Copy',
                              onPressed: () => _copyLink(proxy),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline,
                                  color: cs.error, size: 20),
                              onPressed: () {
                                setState(
                                        () => _proxies.remove(proxy));
                                _save();
                              },
                            ),
                          ],
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

// Small action button widget

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  const _ActionBtn({
    required this.icon,
    required this.label,
    this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c =
        color ?? Theme.of(context).colorScheme.onSurface.withOpacity(0.7);
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: c),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(fontSize: 12, color: c)),
        ],
      ),
    );
  }
}