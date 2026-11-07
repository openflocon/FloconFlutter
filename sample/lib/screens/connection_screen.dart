import 'package:flocon/flocon.dart';
import 'package:flocon_qr_scanner/flocon_qr_scanner.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/sample_theme.dart';
import '../widgets/connection_chip.dart';
import '../widgets/sample_widgets.dart';

/// Connects the app to Flocon Desktop at an IP address, with `Flocon.connect`, and closes it with `Flocon.disconnect`.
///
/// The default address (`localhost`) keeps being tried, this one is added. Ports are optional: `host`, `host:wsPort` or
/// `host:wsPort:httpPort`; an omitted port is the configured one.
class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  static const _key = 'flocon.sample.address';
  final _address = TextEditingController();
  FloconConnectResult? _result;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      final saved = prefs.getString(_key);
      if (saved != null && mounted) _address.text = saved;
    });
  }

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final target = _address.text.trim();
    if (target.isEmpty || _isConnecting) return;
    setState(() => _isConnecting = true);
    final result = await Flocon.connect(target);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, target);
    if (mounted) {
      setState(() {
        _result = result;
        _isConnecting = false;
      });
    }
  }

  Future<void> _disconnect() async {
    await Flocon.disconnect();
    if (mounted) setState(() => _result = null);
  }

  Future<void> _scan() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: SampleTheme.bg,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: FloconQrScannerView(
          onResult: (result) {
            setState(() => _result = result);
            if (result is FloconConnectResultConnected) Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  ({String text, bool isError})? get _message => switch (_result) {
        null => null,
        FloconConnectResultConnected() => (text: '✓ Connected', isError: false),
        FloconConnectResultNotStarted() => (text: '✕ Flocon is not started', isError: true),
        FloconConnectResultInvalidAddress(:final reason) => (text: '✕ $reason', isError: true),
        FloconConnectResultFailed(:final reason) => (text: '✕ $reason', isError: true),
      };

  @override
  Widget build(BuildContext context) {
    final message = _message;
    return Scaffold(
      appBar: AppBar(title: const Text('Remote connection', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600))),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          const Row(children: [
            SampleCategoryIcon(icon: Icons.wifi, category: SampleCategory.neutral, size: 44),
            SizedBox(width: 12),
            Expanded(child: Text('Connect to Flocon Desktop by IP', style: TextStyle(color: SampleTheme.inkMuted))),
          ]),
          const SizedBox(height: 20),
          SampleSection(title: 'Status', children: [
            StreamBuilder<FloconConnectionState>(
              stream: Flocon.connectionStates,
              initialData: Flocon.connectionState,
              builder: (context, snapshot) {
                final state = snapshot.data ?? const FloconIdle();
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: connectionColor(state))),
                    const SizedBox(width: 12),
                    Expanded(child: Text(connectionLabel(state), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                  ]),
                );
              },
            ),
          ]),
          const SizedBox(height: 20),
          SampleSection(title: 'Flocon Desktop address', children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: SampleTextField(controller: _address, hint: '192.168.1.20 or 192.168.1.20:10023:10024', onSubmitted: (_) => _connect())),
                  const SizedBox(width: 12),
                  SampleButton(_isConnecting ? '…' : 'Connect', onPressed: _isConnecting ? null : _connect),
                ]),
                const SizedBox(height: 12),
                SampleButton('Scan QR code', icon: Icons.qr_code_scanner, onPressed: _scan),
                const SizedBox(height: 12),
                SampleButton('Disconnect', onPressed: _isConnecting ? null : _disconnect),
                if (message != null) ...[
                  const SizedBox(height: 12),
                  Text(message.text, style: TextStyle(fontSize: 13, color: message.isError ? SampleTheme.error : SampleTheme.success)),
                ],
              ]),
            ),
          ]),
          const SizedBox(height: 20),
          const SampleInfoCard(
            'The SDK keeps trying its default address (localhost, or 10.0.2.2 on the Android emulator) and also connects to this one. '
            'Add ports with host:wsPort:httpPort (192.168.1.20:10023:10024), otherwise the configured ports (9023 and 9024 by default) are used. '
            'The last address that worked is tried again at the next launch.',
            tint: SampleTheme.accent,
          ),
        ]),
      ),
    );
  }
}
