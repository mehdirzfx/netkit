import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:typed_data';

class QrScreen extends StatefulWidget {
  const QrScreen({super.key});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  String _qrData = '';
  final GlobalKey _repaintKey = GlobalKey();
  bool _saving = false;

  final List<Map<String, String>> _presets = [
    {'label': 'Website', 'prefix': 'https://'},
    {'label': 'WhatsApp', 'prefix': 'https://wa.me/'},
    {'label': 'Telegram', 'prefix': 'https://t.me/'},
    {'label': 'Email', 'prefix': 'mailto:'},
    {'label': 'Phone', 'prefix': 'tel:+'},
    {'label': 'WiFi', 'prefix': 'WIFI:S:MyNetwork;T:WPA;P:password;;'},
  ];

  void _generate() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    setState(() => _qrData = text);
  }

  void _applyPreset(String prefix) {
    _textController.text = prefix;
    _textController.selection =
        TextSelection.fromPosition(TextPosition(offset: prefix.length));
  }

  Future<Uint8List?> _captureQrBytes() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
      as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveToGallery() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final bytes = await _captureQrBytes();
      if (bytes == null) throw Exception('Could not render QR');
      final result = await SaverGallery.saveImage(
        bytes,
        quality: 100,
        name: 'netkit_qr_${DateTime.now().millisecondsSinceEpoch}',
        androidRelativePath: 'Pictures/Netkit',
        androidExistNotSave: false,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              result.isSuccess ? '✅ Saved to gallery!' : '❌ Save failed'),
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _shareQr() async {
    try {
      final bytes = await _captureQrBytes();
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/netkit_qr.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'QR: $_qrData');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Share failed: $e')));
      }
    }
  }

  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Copied!'), duration: Duration(seconds: 1)),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code'),
        backgroundColor: cs.surfaceVariant,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Templates
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Templates',
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(color: cs.primary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _presets
                          .map((p) => ActionChip(
                        label: Text(p['label']!),
                        onPressed: () =>
                            _applyPreset(p['prefix']!),
                      ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Input
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Text / URL',
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(color: cs.primary)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _textController,
                      maxLines: 3,
                      textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(
                        hintText: 'Enter text, URL, or any content...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            FilledButton.icon(
              onPressed: _generate,
              icon: const Icon(Icons.qr_code),
              label: const Text('Generate QR Code'),
            ),
            const SizedBox(height: 16),

            // QR Result
            if (_qrData.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      RepaintBoundary(
                        key: _repaintKey,
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(16),
                          child: QrImageView(
                            data: _qrData,
                            version: QrVersions.auto,
                            size: 240,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Colors.black,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _qrData.length > 60
                            ? '${_qrData.substring(0, 60)}...'
                            : _qrData,
                        style: Theme.of(context).textTheme.bodySmall,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _saving ? null : _saveToGallery,
                            icon: _saving
                                ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            )
                                : const Icon(Icons.photo_library),
                            label: Text(
                                _saving ? 'Saving...' : 'Save to Gallery'),
                          ),
                          ElevatedButton.icon(
                            onPressed: _shareQr,
                            icon: const Icon(Icons.share),
                            label: const Text('Share'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _copyText(_qrData),
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy text'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            //  Scan disabled notice
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(Icons.qr_code_scanner,
                        color: cs.onSurfaceVariant.withOpacity(0.5)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'QR scanning will be added in later versions.',
                        style: TextStyle(
                            color: cs.onSurfaceVariant.withOpacity(0.6),
                            fontSize: 13),
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