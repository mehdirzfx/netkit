import 'package:flutter/material.dart';
import 'encoder_screen.dart';
import 'qr_screen.dart';
import 'ping_screen.dart';
import 'proxy_screen.dart';
import 'ip_check_screen.dart';
import 'about_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    EncoderScreen(),
    QrScreen(),
    PingScreen(),
    ProxyScreen(),
    IpCheckScreen(),
    AboutScreen(),
  ];

  final List<NavigationDestination> _destinations = const [
    NavigationDestination(
      icon: Icon(Icons.code_outlined),
      selectedIcon: Icon(Icons.code),
      label: 'Encoder',
    ),
    NavigationDestination(
      icon: Icon(Icons.qr_code_2_outlined),
      selectedIcon: Icon(Icons.qr_code_2),
      label: 'QR Code',
    ),
    NavigationDestination(
      icon: Icon(Icons.network_ping_outlined),
      selectedIcon: Icon(Icons.network_ping),
      label: 'Ping',
    ),
    NavigationDestination(
      icon: Icon(Icons.vpn_key_outlined),
      selectedIcon: Icon(Icons.vpn_key),
      label: 'Proxy',
    ),
    NavigationDestination(
      icon: Icon(Icons.location_on_outlined),
      selectedIcon: Icon(Icons.location_on),
      label: 'My IP',
    ),
    NavigationDestination(
      icon: Icon(Icons.info_outline),
      selectedIcon: Icon(Icons.info),
      label: 'About',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: _destinations,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}