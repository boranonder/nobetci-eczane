import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/drug_model.dart';
import '../../models/pharmacy_model.dart';
import '../../providers/query_provider.dart';
import '../queries/queries_screen.dart';

class DrugSearchScreen extends StatefulWidget {
  final PharmacyModel? pharmacy;

  const DrugSearchScreen({super.key, this.pharmacy});

  @override
  State<DrugSearchScreen> createState() => _DrugSearchScreenState();
}

class _DrugSearchScreenState extends State<DrugSearchScreen> {
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  final List<DrugModel> _drugList = []; // sorgu listesi

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _addDrugFromText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _drugList.add(DrugModel(name: text));
      _textController.clear();
    });
  }

  void _addDrug(DrugModel drug) {
    if (_drugList.any((d) => d.displayName == drug.displayName)) return;
    setState(() => _drugList.add(drug));
  }

  void _removeDrug(int index) {
    setState(() => _drugList.removeAt(index));
  }

  Future<void> _pickAndAnalyze(ImageSource source) async {
    final xFile = await _picker.pickImage(source: source, imageQuality: 80);
    if (xFile == null) return;
    setState(() {
      _selectedImage = File(xFile.path);
    });

    final provider = context.read<QueryProvider>();
    final drugs = await provider.extractDrugsFromImage(_selectedImage!);
    if (!mounted) return;

    if (drugs.isEmpty) {
      _showSnack('Görselde ilaç bulunamadı.');
      return;
    }

    for (final drug in drugs) {
      _addDrug(drug);
    }
    setState(() => _selectedImage = null);
    _showSnack('${drugs.length} ilaç listeye eklendi.');
  }

  Future<void> _submitQuery() async {
    if (_drugList.isEmpty) {
      _showSnack('Listeye en az bir ilaç ekleyin.');
      return;
    }
    if (widget.pharmacy == null) {
      _showSnack('Lütfen haritadan bir eczane seçin.');
      return;
    }

    final provider = context.read<QueryProvider>();
    await provider.sendQuery(drugs: _drugList, pharmacy: widget.pharmacy!);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const QueriesScreen()),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final isProcessing = context.watch<QueryProvider>().isProcessing;
    final processingStatus = context.watch<QueryProvider>().processingStatus;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pharmacy?.name ?? 'İlaç Ara'),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.pharmacy != null) _buildPharmacyCard(),
            const SizedBox(height: 20),

            // ─── Metin girişi ───────────────────────────────────────
            const Text('İlaç Ekle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    onSubmitted: (_) => _addDrugFromText(),
                    decoration: const InputDecoration(
                      hintText: 'İlaç adı ve mg (örn: Parol 500mg)',
                      prefixIcon: Icon(Icons.search, color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addDrugFromText,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  child: const Text('Ekle'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ─── Görsel seçenekleri ─────────────────────────────────
            const Row(children: [
              Expanded(child: Divider()),
              Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('veya fotoğraf', style: TextStyle(color: AppColors.textSecondary))),
              Expanded(child: Divider()),
            ]),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _imageButton(Icons.camera_alt_outlined, 'İlaç Fotoğrafı', () => _pickAndAnalyze(ImageSource.camera))),
                const SizedBox(width: 12),
                Expanded(child: _imageButton(Icons.receipt_long_outlined, 'Reçete', () => _pickAndAnalyze(ImageSource.gallery))),
                const SizedBox(width: 12),
                Expanded(child: _imageButton(Icons.edit_note_outlined, 'El Yazısı', () => _pickAndAnalyze(ImageSource.camera))),
              ],
            ),

            // ─── İşleniyor göstergesi ───────────────────────────────
            if (isProcessing && processingStatus != null) ...[
              const SizedBox(height: 16),
              Row(children: [
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 12),
                Text(processingStatus, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              ]),
            ],

            // ─── Sorgu listesi ──────────────────────────────────────
            if (_drugList.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  const Text('Sorgu Listesi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                    child: Text('${_drugList.length}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._drugList.asMap().entries.map((entry) => _buildDrugItem(entry.key, entry.value)),
            ],

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (isProcessing || _drugList.isEmpty) ? null : _submitQuery,
                icon: const Icon(Icons.phone_in_talk_rounded),
                label: Text(_drugList.isEmpty ? 'Listeye ilaç ekleyin' : 'Eczaneyi Ara (${_drugList.length} ilaç)'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrugItem(int index, DrugModel drug) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.medication, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(drug.displayName, style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          ),
          GestureDetector(
            onTap: () => _removeDrug(index),
            child: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildPharmacyCard() {
    final p = widget.pharmacy!;
    final color = p.isDuty ? AppColors.duty : (p.isOpen ? AppColors.open : AppColors.closed);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_pharmacy, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              if (p.address != null) Text(p.address!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Text(p.statusLabel, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _imageButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}
