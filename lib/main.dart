import 'dart:async';

import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;

void main() {
  runApp(const ByteLocApp());
}

Future<void> _openPortfolio() async {
  // Replace this with your real portfolio URL:
  final Uri url = Uri.parse('https://kobyte-25.github.io/Portfolio-version-2/');

  if (!await launchUrl(
    url,
    mode: LaunchMode.externalApplication,
  )) {
    // If it fails, you could log or show a SnackBar later.
  }
}

class ByteLocApp extends StatelessWidget {
  const ByteLocApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ByteLoc',
      theme: ThemeData.dark(),
      home: const ByteLocHomePage(),
    );
  }
}

class ByteLocHomePage extends StatefulWidget {
  const ByteLocHomePage({super.key});

  @override
  State<ByteLocHomePage> createState() => _ByteLocHomePageState();
}

class _ByteLocHomePageState extends State<ByteLocHomePage> {
  bool _hasInternet = false;
  StreamSubscription<InternetStatus>? _internetSubscription;

  // For later we will replace these with real values and saving logic.
  String _tid = 'te';
  String _deviceId = '01';
  String _url = '';
  String _latText = '-';
  String _lonText = '-';
  StreamSubscription<Position>? _positionSubscription;

  Timer? _sendTimer;
  bool _isEditingConfig = false;
  String _sendStatus = 'idle'; // for bottom status line

  @override
  void initState() {
    super.initState();
    _startInternetMonitoring();
    _initLocation();
    _loadConfig();    
  }

  void _startInternetMonitoring() {
    _internetSubscription =
        InternetConnection().onStatusChange.listen((InternetStatus status) {
      final hasInternet = status == InternetStatus.connected;
      if (mounted) {
        setState(() {
          _hasInternet = hasInternet;
        });
      }

      if (hasInternet) {
        if (_canSend()) {
          _startSendingTimer();
        }
      } else {
        _stopSendingTimer(reason: 'idle (no internet)');
      }

    });
  }

  @override
  void dispose() {
    _internetSubscription?.cancel();
    _positionSubscription?.cancel();
    _sendTimer?.cancel();
    super.dispose();
  }

  void _editTid() async {
    _isEditingConfig = true;
    _stopSendingTimer(reason: 'idle (editing Tid)');
    
    final controller = TextEditingController(text: _tid);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit TID'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'TID'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _tid = result;
      });
      await _saveConfig();
    }

    _isEditingConfig=false;

    if (_canSend()) {
      _startSendingTimer();
    }
  }

  void _editDeviceId() async {
    _isEditingConfig = true;
    _stopSendingTimer(reason: 'idle (editing Device Id)');
    
    final controller = TextEditingController(text: _deviceId);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Device ID'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Device ID'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _deviceId = result;
      });
      await _saveConfig();
    }

    _isEditingConfig=false;

    if (_canSend()) {
      _startSendingTimer();
    }
  }

  void _editUrl() async {
    _isEditingConfig = true;
    _stopSendingTimer(reason: 'idle (editing URL)');
    
    final controller = TextEditingController(text: _url);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit URL'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'HTTP endpoint URL'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        _url = result;
      });
      await _saveConfig();
    }

    _isEditingConfig=false;

    if (_canSend()) {
      _startSendingTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Later we will replace lat/lon placeholders with real GPS values.
    // const String lat = '-';
    // const String lon = '-';

    return WillPopScope(
      onWillPop: () async {
        final shouldQuit = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Quit ByteLoc'),
              content: const Text('Do you want to quit?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('No'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Yes'),
                ),
              ],
            );
          },
        );
        return shouldQuit ?? false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('ByteLoc'),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HelpPage()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'ByteLoc',
                  applicationVersion: '1.2.1',
                  children: [
                    const Text('Developed by Ko Byte.'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _openPortfolio,
                      child: const Text(
                      'Visit: https://kobyte-25.github.io/Portfolio-version-2/',
                      style: TextStyle(
                        color: Colors.lightBlueAccent,
                        decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8), 
                    const Text('Simple GPS tracker that sends JSON to your endpoint.'),
                    const SizedBox(height: 8),                    
                    const Text('Developed for demo usage for your projects.'),
                    const SizedBox(height: 8),
                    const SizedBox(height: 16),
                    const Text(
                      'License',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'ByteLoc is released under the MIT License. See the LICENSE file in the repository for details.',
                      style: TextStyle(color: Colors.white70),
                    ),                   
                  ],
                );
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Network status line
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _hasInternet ? Colors.green[800] : Colors.red[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _hasInternet ? 'Online - connected to internet' : 'Waiting for network...',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),

              // Top panel: location + IDs (lat/lon placeholder for now)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lat: $_latText, Lon: $_lonText', style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 8),
                    Text('TID: $_tid, Device ID: $_deviceId',
                        style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Mode + config section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mode: http',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _editUrl,
                      child: Row(
                        children: [
                          const Text('URL: ',
                              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Text(
                              _url.isEmpty ? '(tap to set URL)' : _url,
                              style: const TextStyle(color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _editTid,
                      child: Text(
                        'TID: $_tid (tap to edit)',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _editDeviceId,
                      child: Text(
                        'Device ID: $_deviceId (tap to edit)',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

                            const SizedBox(height: 16),

              // JSON format panel
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'JSON data are sent in this format:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    SelectableText(
                      '{\n'
                      '  "lat": $_latText,\n'
                      '  "lon": $_lonText,\n'
                      '  "tid": $_tid,\n'
                      '  "deviceId": $_deviceId,\n'
                      '  "tst": ${DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000},\n'
                      '  "mode": "http"\n'
                      '}',
                      style: TextStyle(
                        color: Colors.white70,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Placeholder for send status (to be implemented when we add HTTP)
              Text(
                'Send status: $_sendStatus',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _initLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled. We just show '-' and return.
      if (mounted) {
        setState(() {
          _latText = '-';
          _lonText = '-';
        });
      }
      return;
    }

    // Check permission.
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      // Permissions are denied (or denied forever).
      if (mounted) {
        setState(() {
          _latText = 'perm denied';
          _lonText = 'perm denied';
        });
      }
      return;
    }

    // If we reach here, we have permission. Start listening to position updates.
    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _latText = position.latitude.toStringAsFixed(9);
          _lonText = position.longitude.toStringAsFixed(9);
        });
      }
    });
  }
  
  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _tid = prefs.getString('tid') ?? 'te';
      _deviceId = prefs.getString('deviceId') ?? '01';
      _url = prefs.getString('url') ?? '';
    });

    // After loading config, see if we can start sending.
    if (_canSend()) {
      _startSendingTimer();
    }
  }

  Future<void> _saveConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tid', _tid);
    await prefs.setString('deviceId', _deviceId);
    await prefs.setString('url', _url);
  }

  bool _canSend() {
    return _hasInternet &&
        !_isEditingConfig &&
        _url.isNotEmpty &&
        _latText != '-' &&
        _latText != 'perm denied';
  }

  void _startSendingTimer() {
    _sendTimer?.cancel();
    if (!_canSend()) {
      setState(() {
        _sendStatus = 'idle (waiting for URL, internet, or GPS)';
      });
      return;
    }

    _sendStatus = 'sending every 1 second...';

    _sendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_canSend()) {
        // Conditions no longer valid, stop timer.
        timer.cancel();
        setState(() {
          _sendStatus = 'idle (conditions not met)';
        });
        _sendTimer = null;
        return;
      }
      _sendLocation();
    });
  }

  void _stopSendingTimer({String? reason}) {
    if (_sendTimer != null) {
      _sendTimer!.cancel();
      _sendTimer = null;
    }
    setState(() {
      _sendStatus = reason ?? 'idle (sending stopped)';
    });
  }

  Future<void> _sendLocation() async {
    try {
      final uri = Uri.parse(_url);

      final body = <String, dynamic>{
        'lat': double.tryParse(_latText),
        'lon': double.tryParse(_lonText),
        'tid': _tid,
        'deviceId': _deviceId,
        'tst': DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000,
        'mode': 'http',
      };

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        setState(() {
          _sendStatus = 'Last send OK (${response.statusCode})';
        });
      } else {
        setState(() {
          _sendStatus =
              'Send error: HTTP ${response.statusCode}'; // e.g. 404, 500
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sendStatus = 'Send error: $e';
      });
    }
  }
}


class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How to use ByteLoc'),
      ),
      backgroundColor: Colors.black,
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overview',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'ByteLoc reads your device GPS and sends your position as JSON to a HTTP endpoint every second.',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 16),
              Text(
                'Requirements',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '• Location (GPS) must be enabled on the device.\n'
                '• Mobile data or Wi‑Fi must be connected.\n'
                '• A valid HTTP URL, TID and Device ID must be configured.',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 16),
              Text(
                'Steps to send coordinates',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '1. Open ByteLoc and allow location permission when asked.\n'
                '2. Check the top banner shows Online and GPS coordinates.\n'
                '3. Tap URL and enter your server endpoint, then Save.\n'
                '4. Optionally edit TID and Device ID, then Save.\n'
                '5. Keep the app open (screen on) to continue sending.\n'
                '   Sending stops if the app is closed or the URL is cleared.',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 16),
              Text(
                'Editing settings',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '• While editing URL, TID or Device ID, sending is paused.\n'
                '• After you tap Save, sending restarts automatically if internet and GPS are available.',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 16),
              Text(
                'Notes',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '• This app is intended for demo/testing purposes.\n'
                '• Continuous GPS + network use can drain battery faster.\n'
                '• Make sure you comply with local privacy and tracking laws.',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}