import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class IpInfo {
  final String ip;
  final String country;
  final String countryCode;
  final String city;
  final String isp;
  final String org;
  final bool isVpn;
  final double? lat;
  final double? lon;

  IpInfo({
    required this.ip,
    required this.country,
    required this.countryCode,
    required this.city,
    required this.isp,
    required this.org,
    required this.isVpn,
    this.lat,
    this.lon,
  });

  factory IpInfo.fromJson(Map<String, dynamic> j) => IpInfo(
        ip: j['ip'] ?? 'Unknown',
        country: j['country_name'] ?? j['country'] ?? 'Unknown',
        countryCode: j['country_code'] ?? j['countryCode'] ?? '',
        city: j['city'] ?? 'Unknown',
        isp: j['org'] ?? j['isp'] ?? 'Unknown',
        org: j['org'] ?? 'Unknown',
        isVpn: false,
        lat: (j['latitude'] ?? j['lat'])?.toDouble(),
        lon: (j['longitude'] ?? j['lon'])?.toDouble(),
      );
}

class IpCheckScreen extends StatefulWidget {
  const IpCheckScreen({super.key});

  @override
  State<IpCheckScreen> createState() => _IpCheckScreenState();
}

class _IpCheckScreenState extends State<IpCheckScreen> {
  IpInfo? _info;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchIp();
  }

  Future<void> _fetchIp() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Try ipapi.co first
      final res = await http
          .get(Uri.parse('https://ipapi.co/json/'))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _info = IpInfo(
            ip: data['ip'] ?? 'Unknown',
            country: data['country_name'] ?? 'Unknown',
            countryCode: data['country_code'] ?? '',
            city: data['city'] ?? 'Unknown',
            isp: data['org'] ?? 'Unknown',
            org: data['org'] ?? 'Unknown',
            isVpn: false,
            lat: data['latitude']?.toDouble(),
            lon: data['longitude']?.toDouble(),
          );
          _loading = false;
        });
      } else {
        throw Exception('Status ${res.statusCode}');
      }
    } catch (_) {
      // Fallback to ip-api.com
      try {
        final res = await http
            .get(Uri.parse('http://ip-api.com/json/'))
            .timeout(const Duration(seconds: 10));
        final data = jsonDecode(res.body);
        setState(() {
          _info = IpInfo(
            ip: data['query'] ?? 'Unknown',
            country: data['country'] ?? 'Unknown',
            countryCode: data['countryCode'] ?? '',
            city: data['city'] ?? 'Unknown',
            isp: data['isp'] ?? 'Unknown',
            org: data['org'] ?? 'Unknown',
            isVpn: false,
            lat: data['lat']?.toDouble(),
            lon: data['lon']?.toDouble(),
          );
          _loading = false;
        });
      } catch (e) {
        setState(() {
          _error = 'Failed to fetch IP info.\nCheck your connection.';
          _loading = false;
        });
      }
    }
  }

  void _copyIp() {
    if (_info == null) return;
    Clipboard.setData(ClipboardData(text: _info!.ip));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('IP copied!'), duration: Duration(seconds: 1)),
    );
  }

  String _countryFlag(String code) {
    if (code.length != 2) return '🌐';
    return String.fromCharCodes(
      code.toUpperCase().codeUnits.map((c) => c + 127397),
    );
  }

  bool get _isIranIp =>
      _info?.countryCode.toUpperCase() == 'IR';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My IP'),
        backgroundColor: colorScheme.surfaceVariant,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _fetchIp,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_off,
                          size: 64, color: colorScheme.error),
                      const SizedBox(height: 16),
                      Text(_error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colorScheme.error)),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _fetchIp,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Status Card
                      Card(
                        color: _isIranIp
                            ? colorScheme.errorContainer
                            : colorScheme.primaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Text(
                                _info != null
                                    ? _countryFlag(_info!.countryCode)
                                    : '🌐',
                                style: const TextStyle(fontSize: 56),
                              ),
                              const SizedBox(height: 8),
                              SelectableText(
                                _info?.ip ?? '',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                  color: _isIranIp
                                      ? colorScheme.onErrorContainer
                                      : colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isIranIp
                                    ? '⚠️ Iranian IP – VPN might not be active'
                                    : '✅ Non-Iranian IP – VPN seems active',
                                style: TextStyle(
                                  color: _isIranIp
                                      ? colorScheme.onErrorContainer
                                      : colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: _copyIp,
                                icon: const Icon(Icons.copy, size: 18),
                                label: const Text('Copy IP'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Details Card
                      if (_info != null)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Details',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(color: colorScheme.primary),
                                ),
                                const Divider(),
                                _InfoRow(
                                    icon: Icons.flag,
                                    label: 'Country',
                                    value: _info!.country),
                                _InfoRow(
                                    icon: Icons.location_city,
                                    label: 'City',
                                    value: _info!.city),
                                _InfoRow(
                                    icon: Icons.business,
                                    label: 'ISP / Org',
                                    value: _info!.isp),
                                if (_info!.lat != null && _info!.lon != null)
                                  _InfoRow(
                                    icon: Icons.my_location,
                                    label: 'Coords',
                                    value:
                                        '${_info!.lat!.toStringAsFixed(4)}, ${_info!.lon!.toStringAsFixed(4)}',
                                  ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Tip Card
                      Card(
                        color: colorScheme.secondaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: colorScheme.onSecondaryContainer),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Tap Refresh after connecting to VPN to verify your IP has changed.',
                                  style: TextStyle(
                                      color: colorScheme.onSecondaryContainer),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 12),
          Text('$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
