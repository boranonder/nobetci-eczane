import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/pharmacy_model.dart';
import '../../providers/location_provider.dart';
import '../../providers/pharmacy_provider.dart';
import '../../widgets/pharmacy_bottom_sheet.dart';

const _defaultCenter = LatLng(41.0082, 28.9784);

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  bool _initialized = false;
  LatLng? _pinnedLocation; // Kullanıcının işaretlediği konum

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    if (_initialized) return;
    _initialized = true;
    final loc = context.read<LocationProvider>();
    await loc.fetchLocation();
    if (!mounted) return;
    final pos = loc.position;
    final lat = pos?.latitude ?? _defaultCenter.latitude;
    final lon = pos?.longitude ?? _defaultCenter.longitude;
    _mapController.move(LatLng(lat, lon), 14);
    await context.read<PharmacyProvider>().fetchPharmacies(lat, lon);
  }

  Future<void> _refresh() async {
    // Eğer pin varsa ona göre, yoksa GPS konumuna göre yenile
    if (_pinnedLocation != null) {
      await context.read<PharmacyProvider>().fetchPharmacies(
            _pinnedLocation!.latitude,
            _pinnedLocation!.longitude,
          );
      return;
    }
    final loc = context.read<LocationProvider>();
    await loc.fetchLocation();
    if (!mounted) return;
    final pos = loc.position;
    final lat = pos?.latitude ?? _defaultCenter.latitude;
    final lon = pos?.longitude ?? _defaultCenter.longitude;
    _mapController.move(LatLng(lat, lon), 14);
    await context.read<PharmacyProvider>().fetchPharmacies(lat, lon);
  }

  void _onLongPress(TapPosition _, LatLng point) {
    setState(() => _pinnedLocation = point);
    _mapController.move(point, _mapController.camera.zoom);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Konum işaretlendi. Yenile butonuna bas.'),
        action: SnackBarAction(label: 'Şimdi Yenile', onPressed: _refresh),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _clearPin() {
    setState(() => _pinnedLocation = null);
    _refresh();
  }

  void _centerOnUser() {
    final pos = context.read<LocationProvider>().position;
    final center = pos != null ? LatLng(pos.latitude, pos.longitude) : _defaultCenter;
    _mapController.move(center, 15);
  }

  void _zoom(double delta) {
    final camera = _mapController.camera;
    _mapController.move(camera.center, camera.zoom + delta);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildMap(),
          _buildZoomButtons(),
          _buildLegend(),
          _buildLoadingOverlay(),
          _buildStatusBar(),
          if (_pinnedLocation != null) _buildPinBanner(),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'refresh',
            onPressed: _refresh,
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.primary,
            elevation: 4,
            child: const Icon(Icons.refresh),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'locate',
            onPressed: _centerOnUser,
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.primary,
            elevation: 4,
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    final locationProvider = context.watch<LocationProvider>();
    final pharmacyProvider = context.watch<PharmacyProvider>();
    final pos = locationProvider.position;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _defaultCenter,
        initialZoom: 13,
        onLongPress: _onLongPress,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.boranonder.nobetci_eczane',
        ),
        MarkerLayer(markers: [
          // GPS konumu — mavi nokta
          if (pos != null)
            Marker(
              point: LatLng(pos.latitude, pos.longitude),
              width: 20,
              height: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 3)],
                ),
              ),
            ),
          // İşaretlenen konum — turuncu pin
          if (_pinnedLocation != null)
            Marker(
              point: _pinnedLocation!,
              width: 40,
              height: 48,
              alignment: const Alignment(0, -1),
              child: GestureDetector(
                onTap: _clearPin,
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha: 0.4), blurRadius: 6)],
                      ),
                      child: const Icon(Icons.push_pin, color: Colors.white, size: 18),
                    ),
                    Container(width: 2, height: 10, color: Colors.orange),
                  ],
                ),
              ),
            ),
        ]),
        MarkerLayer(
          markers: pharmacyProvider.allPharmacies.map(_buildMarker).toList(),
        ),
      ],
    );
  }

  Marker _buildMarker(PharmacyModel pharmacy) {
    final Color color;
    if (pharmacy.isDuty) {
      color = AppColors.duty;
    } else if (pharmacy.isOpen) {
      color = AppColors.open;
    } else {
      color = AppColors.closed;
    }

    return Marker(
      point: LatLng(pharmacy.lat, pharmacy.lon),
      width: 36,
      height: 36,
      child: GestureDetector(
        onTap: () => _showPharmacySheet(pharmacy),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6, spreadRadius: 1)],
          ),
          child: const Icon(Icons.local_pharmacy, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  void _showPharmacySheet(PharmacyModel pharmacy) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PharmacyBottomSheet(pharmacy: pharmacy),
    );
  }

  Widget _buildPinBanner() {
    return Positioned(
      top: 50,
      left: 16,
      right: 80,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6)],
        ),
        child: Row(
          children: [
            const Icon(Icons.push_pin, color: Colors.orange, size: 16),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('İşaretlenen konuma göre', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            ),
            GestureDetector(
              onTap: _clearPin,
              child: const Icon(Icons.close, size: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoomButtons() {
    return Positioned(
      right: 16,
      top: 100,
      child: Column(
        children: [
          _zoomButton(Icons.add, () => _zoom(1)),
          const SizedBox(height: 4),
          _zoomButton(Icons.remove, () => _zoom(-1)),
        ],
      ),
    );
  }

  Widget _zoomButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Positioned(
      bottom: 90,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _legendItem(AppColors.duty, 'Nöbetçi'),
            const SizedBox(height: 4),
            _legendItem(AppColors.open, 'Açık'),
            const SizedBox(height: 4),
            _legendItem(AppColors.closed, 'Kapalı'),
            const SizedBox(height: 4),
            _legendItem(Colors.orange, 'İşaretli konum'),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildStatusBar() {
    return Consumer<PharmacyProvider>(
      builder: (_, provider, child) {
        if (provider.isLoading) return const SizedBox.shrink();

        final String text;
        final Color color;

        if (provider.error != null) {
          text = '⚠️ ${provider.error}';
          color = AppColors.error;
        } else if (provider.allPharmacies.isEmpty) {
          text = 'Eczane bulunamadı — Yenile tuşuna bas';
          color = AppColors.textSecondary;
        } else {
          text = '${provider.allPharmacies.length} eczane yüklendi';
          color = AppColors.primary;
        }

        return Positioned(
          top: 16,
          left: 16,
          right: 80,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6)],
            ),
            child: Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
          ),
        );
      },
    );
  }

  Widget _buildLoadingOverlay() {
    return Consumer<PharmacyProvider>(
      builder: (_, provider, child) {
        if (!provider.isLoading) return const SizedBox.shrink();
        return Positioned(
          top: 60,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 8),
                  Text('Eczaneler yükleniyor...', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
