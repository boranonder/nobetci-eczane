import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/app_colors.dart';
import '../models/pharmacy_model.dart';
import '../screens/search/drug_search_screen.dart';

class PharmacyBottomSheet extends StatelessWidget {
  final PharmacyModel pharmacy;

  const PharmacyBottomSheet({super.key, required this.pharmacy});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textHint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _StatusBadge(pharmacy: pharmacy),
              const Spacer(),
              if (pharmacy.phone != null)
                IconButton(
                  onPressed: () => _callPhone(pharmacy.phone!),
                  icon: const Icon(Icons.phone, color: AppColors.primary),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            pharmacy.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          if (pharmacy.address != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    pharmacy.address!,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
          if (pharmacy.phone != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  pharmacy.phone!,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DrugSearchScreen(pharmacy: pharmacy),
                  ),
                );
              },
              icon: const Icon(Icons.search),
              label: const Text('İlaç Sorgula'),
            ),
          ),
          const SizedBox(height: 12),
          if (pharmacy.phone != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openWhatsApp(pharmacy.phone!),
                icon: const Icon(Icons.message_outlined),
                label: const Text("WhatsApp'ta Aç"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF25D366),
                  side: const BorderSide(color: Color(0xFF25D366)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  void _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  void _openWhatsApp(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    final number = cleaned.startsWith('0') ? '9$cleaned'.substring(1) : cleaned;
    final uri = Uri.parse('whatsapp://send?phone=$number');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }
}

class _StatusBadge extends StatelessWidget {
  final PharmacyModel pharmacy;

  const _StatusBadge({required this.pharmacy});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final Color bg;

    if (pharmacy.isDuty) {
      color = AppColors.duty;
      bg = AppColors.dutyLight;
    } else if (pharmacy.isOpen) {
      color = AppColors.open;
      bg = AppColors.primaryLight;
    } else {
      color = AppColors.closed;
      bg = const Color(0xFFF5F5F5);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(pharmacy.statusLabel, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
