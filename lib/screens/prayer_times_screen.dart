import 'package:flutter/material.dart';
import 'package:barakah_app/services/prayer_times_service.dart';
import 'package:barakah_app/theme/app_theme.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  final PrayerTimesService _service = PrayerTimesService();
  List<PrayerTime> _prayers = [];
  Map<String, String> _hijriDate = {};
  bool _isLoading = true;
  bool _isRamadan = false;

  // Default coordinates (Mecca) - user can change
  double _latitude = 21.4225;
  double _longitude = 39.8262;
  String _locationName = 'Mecca, Saudi Arabia';
  int _method = 4; // Umm Al-Qura

  final Map<int, String> _methods = {
    1: 'University of Islamic Sciences, Karachi',
    2: 'Islamic Society of North America (ISNA)',
    3: 'Muslim World League',
    4: 'Umm Al-Qura University, Makkah',
    5: 'Egyptian General Authority of Survey',
    7: 'Institute of Geophysics, University of Tehran',
    8: 'Gulf Region',
    9: 'Kuwait',
    10: 'Qatar',
    11: 'Majlis Ugama Islam Singapura',
    12: 'UOIF (France)',
    13: 'Diyanet İşleri Başkanlığı (Turkey)',
  };

  @override
  void initState() {
    super.initState();
    _loadPrayerTimes();
  }

  Future<void> _loadPrayerTimes() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _service.getPrayerTimes(
        latitude: _latitude,
        longitude: _longitude,
        method: _method,
      ),
      _service.getHijriDate(),
      _service.isRamadan(),
    ]);
    setState(() {
      _prayers = results[0] as List<PrayerTime>;
      _hijriDate = results[1] as Map<String, String>;
      _isRamadan = results[2] as bool;
      _isLoading = false;
    });
  }

  void _showLocationPicker() {
    final latController = TextEditingController(text: _latitude.toString());
    final lonController = TextEditingController(text: _longitude.toString());
    final nameController = TextEditingController(text: _locationName);

    final presets = {
      'Mecca': [21.4225, 39.8262],
      'Medina': [24.4672, 39.6024],
      'Istanbul': [41.0082, 28.9784],
      'London': [51.5074, -0.1278],
      'New York': [40.7128, -74.0060],
      'Kuala Lumpur': [3.1390, 101.6869],
      'Jakarta': [-6.2088, 106.8456],
      'Cairo': [30.0444, 31.2357],
      'Dubai': [25.2048, 55.2708],
      'Islamabad': [33.6844, 73.0479],
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Set Location',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.deepGreen)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: presets.entries.map((e) => ActionChip(
                label: Text(e.key),
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _locationName = e.key;
                    _latitude = e.value[0];
                    _longitude = e.value[1];
                  });
                  _loadPrayerTimes();
                },
              )).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'City Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: latController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: InputDecoration(
                      labelText: 'Latitude',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: lonController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: InputDecoration(
                      labelText: 'Longitude',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final lat = double.tryParse(latController.text);
                  final lon = double.tryParse(lonController.text);
                  if (lat != null && lon != null) {
                    Navigator.pop(ctx);
                    setState(() {
                      _latitude = lat;
                      _longitude = lon;
                      _locationName = nameController.text.isNotEmpty ? nameController.text : 'Custom';
                    });
                    _loadPrayerTimes();
                  }
                },
                child: const Text('Set Location'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hijriStr = _hijriDate.isNotEmpty
        ? '${_hijriDate['day']} ${_hijriDate['month']} ${_hijriDate['year']} AH'
        : '';

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: const Text('Prayer Times'),
        backgroundColor: AppTheme.deepGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.location_on), onPressed: _showLocationPicker),
          PopupMenuButton<int>(
            icon: const Icon(Icons.settings),
            onSelected: (v) {
              setState(() => _method = v);
              _loadPrayerTimes();
            },
            itemBuilder: (_) => _methods.entries.map((e) =>
                PopupMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 13)))).toList(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.deepGreen))
          : RefreshIndicator(
              onRefresh: _loadPrayerTimes,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Header Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.deepGreen, Color(0xFF2E7D32)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_on, color: Colors.white70, size: 16),
                            const SizedBox(width: 4),
                            Text(_locationName, style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('☪', style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 8),
                        if (hijriStr.isNotEmpty)
                          Text(hijriStr, style: const TextStyle(
                            color: AppTheme.gold, fontSize: 18, fontWeight: FontWeight.bold,
                          )),
                        if (_isRamadan) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.gold.withAlpha(40),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('🌙 Ramadan Mubarak!',
                                style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Prayer Times
                  ..._prayers.map((prayer) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: prayer.isNext ? AppTheme.deepGreen : theme.cardColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        if (prayer.isNext)
                          BoxShadow(color: AppTheme.deepGreen.withAlpha(60), blurRadius: 12, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(
                          _prayerIcon(prayer.name),
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                prayer.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: prayer.isNext ? Colors.white : theme.colorScheme.onSurface,
                                ),
                              ),
                              if (prayer.isNext)
                                const Text('Next Prayer', style: TextStyle(color: AppTheme.gold, fontSize: 12)),
                            ],
                          ),
                        ),
                        Text(
                          prayer.time,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: prayer.isNext ? AppTheme.gold : AppTheme.deepGreen,
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
    );
  }

  String _prayerIcon(String name) {
    switch (name) {
      case 'Fajr': return '🌅';
      case 'Sunrise': return '☀️';
      case 'Dhuhr': return '🌤️';
      case 'Asr': return '⛅';
      case 'Maghrib': return '🌇';
      case 'Isha': return '🌙';
      default: return '🕌';
    }
  }
}
