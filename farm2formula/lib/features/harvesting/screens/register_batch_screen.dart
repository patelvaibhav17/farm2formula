import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../models/harvest_batch.dart';
import '../providers/harvest_provider.dart';

class RegisterBatchScreen extends ConsumerStatefulWidget {
  const RegisterBatchScreen({super.key});

  @override
  ConsumerState<RegisterBatchScreen> createState() => _RegisterBatchScreenState();
}

class _RegisterBatchScreenState extends ConsumerState<RegisterBatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _herbController = TextEditingController();
  final _weightController = TextEditingController();
  
  bool _isLoading = false;
  String _locationStatus = 'Capture GPS to proceed';
  Position? _currentPosition;

  final ImagePicker _picker = ImagePicker();
  String? _imagePath;

  Future<void> _captureLocation() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _locationStatus = 'Lat: ${position.latitude.toStringAsFixed(4)}, Long: ${position.longitude.toStringAsFixed(4)}';
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          _imagePath = photo.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error taking photo: $e')));
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate() || _currentPosition == null || _imagePath == null) {
      if (_currentPosition == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please capture GPS location')));
      } else if (_imagePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please capture a photo of the herb')));
      }
      return;
    }

    final batch = HarvestBatch(
      id: const Uuid().v4(),
      herbName: _herbController.text,
      farmerId: 'farmer_v1', // Hardcoded for demo
      location: '${_currentPosition!.latitude},${_currentPosition!.longitude}',
      weight: double.parse(_weightController.text),
      harvestDate: DateTime.now(),
      imagePath: _imagePath,
    );

    await ref.read(harvestProvider.notifier).addBatch(batch);
    
    // Consensus delay to ensure blockchain ledger is settled before refresh
    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Register Harvest'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(Icons.grass, size: 60, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              'Botanical Passport Data',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _herbController,
              decoration: const InputDecoration(
                labelText: 'Herb Name',
                hintText: 'e.g. Brahmi, Tulsi',
                prefixIcon: Icon(Icons.eco),
              ),
              validator: (v) => v!.isEmpty ? 'Enter herb name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total Weight (kg)',
                prefixIcon: Icon(Icons.scale),
              ),
              validator: (v) => v!.isEmpty ? 'Enter weight' : null,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  if (_imagePath != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_imagePath!),
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    const Icon(Icons.camera_alt, size: 60, color: Colors.grey),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera),
                    label: const Text('Take Herbal Photo'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, color: _currentPosition == null ? Colors.red : Colors.green),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_locationStatus)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _captureLocation,
                    icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.gps_fixed),
                    label: const Text('Capture Hardware GPS'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
              child: const Text('Register Batch on Blockchain'),
            ),
          ],
        ),
      ),
    );
  }
}
