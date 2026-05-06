import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class EncoderScreen extends StatefulWidget {
  const EncoderScreen({super.key});

  @override
  State<EncoderScreen> createState() => _EncoderScreenState();
}

class _EncoderScreenState extends State<EncoderScreen> {
  final TextEditingController _inputController = TextEditingController();
  String _output = '';
  String _selectedMode = 'Base64 Encode';
  bool _hasError = false;

  static const List<int> _appKey = [
    0x41, 0x6E, 0x74, 0x68, 0x72, 0x6F, 0x70, 0x69,
    0x63, 0x21, 0x23, 0x2A, 0x3C, 0x7E, 0x5E, 0x2F,
  ];

  static const String _cipherMarker = '✦';

  final Map<String, List<String>> _modeGroups = {
    'Encoding': [
      'Base64 Encode',
      'Base64 Decode',
      'URL Encode',
      'URL Decode',
      'HEX Encode',
      'HEX Decode',
    ],
    'Hashing': [
      'MD5 Hash',
      'SHA256 Hash',
    ],
    'Custom Cipher': [
      'App Encrypt ✦',
      'App Decrypt ✦',
    ],
  };

  List<int> _xorBytes(List<int> bytes) {
    return List.generate(
      bytes.length,
          (i) => bytes[i] ^ _appKey[i % _appKey.length],
    );
  }

  List<int> _caesarShift(List<int> bytes, int shift) {
    return bytes.map((b) => (b + shift) & 0xFF).toList();
  }

  String _appEncrypt(String text) {
    final bytes = utf8.encode(text);
    final shifted = _caesarShift(bytes, 37);
    final xored = _xorBytes(shifted);
    final reversed = xored.reversed.toList();
    final b64 = base64Encode(reversed);
    return '$_cipherMarker$b64$_cipherMarker';
  }

  String _appDecrypt(String cipher) {
    if (!cipher.startsWith(_cipherMarker) ||
        !cipher.endsWith(_cipherMarker)) {
      throw const FormatException(
          'Invalid cipher text.\nMust start and end with ✦.');
    }
    final b64 = cipher.substring(1, cipher.length - 1);
    final reversed = base64Decode(b64);
    final unrev = reversed.reversed.toList();
    final unxored = _xorBytes(unrev);
    final unshifted = _caesarShift(unxored, 256 - 37);
    return utf8.decode(unshifted);
  }

  void _process() {
    final input = _inputController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _output = '';
        _hasError = false;
      });
      return;
    }
    setState(() {
      _hasError = false;
      try {
        switch (_selectedMode) {
          case 'Base64 Encode':
            _output = base64Encode(utf8.encode(input));
            break;
          case 'Base64 Decode':
            _output = utf8.decode(base64Decode(input));
            break;
          case 'URL Encode':
            _output = Uri.encodeComponent(input);
            break;
          case 'URL Decode':
            _output = Uri.decodeComponent(input);
            break;
          case 'MD5 Hash':
            _output = md5.convert(utf8.encode(input)).toString();
            break;
          case 'SHA256 Hash':
            _output = sha256.convert(utf8.encode(input)).toString();
            break;
          case 'HEX Encode':
            _output = utf8
                .encode(input)
                .map((c) => c.toRadixString(16).padLeft(2, '0'))
                .join(' ');
            break;
          case 'HEX Decode':
            final hex = input.replaceAll(' ', '');
            final bytes = <int>[];
            for (int i = 0; i < hex.length; i += 2) {
              bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
            }
            _output = utf8.decode(bytes);
            break;
          case 'App Encrypt ✦':
            _output = _appEncrypt(input);
            break;
          case 'App Decrypt ✦':
            _output = _appDecrypt(input);
            break;
        }
      } catch (e) {
        _output = 'Error: Invalid input\n${e.toString()}';
        _hasError = true;
      }
    });
  }

  void _copyOutput() {
    if (_output.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _output));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Copied!'), duration: Duration(seconds: 1)),
    );
  }

  Future<void> _pasteInput() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      _inputController.text = data!.text!;
      _process();
    }
  }

  void _swapInputOutput() {
    if (_output.isEmpty || _hasError) return;
    _inputController.text = _output;
    _process();
  }

  void _clear() {
    _inputController.clear();
    setState(() {
      _output = '';
      _hasError = false;
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final List<DropdownMenuItem<String>> dropdownItems = [];
    _modeGroups.forEach((groupName, modes) {
      dropdownItems.add(DropdownMenuItem<String>(
        enabled: false,
        value: '__$groupName',
        child: Text(
          groupName,
          style: TextStyle(
            color: cs.primary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ));
      for (final mode in modes) {
        dropdownItems.add(DropdownMenuItem<String>(
          value: mode,
          child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(mode),
          ),
        ));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Encoder / Decoder'),
        backgroundColor: cs.surfaceVariant,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Operation dropdown
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Operation',
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(color: cs.primary)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedMode,
                      items: dropdownItems,
                      onChanged: (val) {
                        if (val == null || val.startsWith('__')) return;
                        setState(() => _selectedMode = val);
                        _process();
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                      isExpanded: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Input card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Input',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(color: cs.primary)),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.paste, size: 20),
                              tooltip: 'Paste',
                              onPressed: _pasteInput,
                            ),
                            IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              tooltip: 'Clear',
                              onPressed: _clear,
                            ),
                          ],
                        ),
                      ],
                    ),
                    TextField(
                      controller: _inputController,
                      maxLines: 4,
                      textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(
                        hintText: 'Enter text here...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(12),
                      ),
                      onChanged: (_) => _process(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            FilledButton.icon(
              onPressed: _process,
              icon: const Icon(Icons.transform),
              label: Text(_selectedMode),
            ),
            const SizedBox(height: 6),

            if (_output.isNotEmpty && !_hasError)
              OutlinedButton.icon(
                onPressed: _swapInputOutput,
                icon: const Icon(Icons.swap_vert),
                label: const Text('Swap output → input'),
              ),
            const SizedBox(height: 12),

            // Output card
            Card(
              color: _hasError ? cs.errorContainer : cs.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Output',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                              color: _hasError
                                  ? cs.onErrorContainer
                                  : cs.onPrimaryContainer),
                        ),
                        if (_output.isNotEmpty && !_hasError)
                          IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            tooltip: 'Copy',
                            onPressed: _copyOutput,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      _output.isEmpty
                          ? 'Output will appear here...'
                          : _output,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: _hasError
                            ? cs.onErrorContainer
                            : cs.onPrimaryContainer,
                        fontSize: 13,
                      ),
                      textDirection: TextDirection.ltr,
                    ),
                    if (_output.isNotEmpty && !_hasError) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${_output.length} characters',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                            color:
                            cs.onPrimaryContainer.withOpacity(0.7)),
                      ),
                    ],
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