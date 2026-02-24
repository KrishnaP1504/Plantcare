import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/theme.dart';

class DiseaseResultScreen extends StatefulWidget {
  final Map<String, dynamic> resultData;
  final String base64Image;

  const DiseaseResultScreen({
    super.key,
    required this.resultData,
    required this.base64Image,
  });

  @override
  State<DiseaseResultScreen> createState() => _DiseaseResultScreenState();
}

class _DiseaseResultScreenState extends State<DiseaseResultScreen> {
  bool _isSaving = false;

  Future<void> _addToGarden() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        // If this result is actually an AI error, don't try to save it.
        final String plantName =
            widget.resultData['plant_name']?.toString().toLowerCase() ?? '';
        if (plantName.contains('scan error')) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Scan failed – nothing to save. Please scan again."),
            ));
          }
          return;
        }

        // 1. Get Scheduling Info (Default to 7 days if AI doesn't specify)
        final dynamic rawFreq = widget.resultData['watering_frequency'];
        final int frequency = (rawFreq is num && rawFreq.isFinite)
            ? rawFreq.round().clamp(1, 60)
            : 7;

        // 2. Calculate the specific Date
        final DateTime nextWaterDate = DateTime.now().add(Duration(days: frequency));
        
        // 3. SAFE DATA HANDLING (Fixing the Invalid Argument Error)
        // We ensure list fields are never null.
        final List<dynamic> symptomsListRaw =
            widget.resultData['symptoms'] is List
                ? widget.resultData['symptoms']
                : [];
        final List<String> symptomsList =
            symptomsListRaw.map((e) => e.toString()).toList();

        final List<dynamic> treatmentsListRaw =
            widget.resultData['treatments'] is List
                ? widget.resultData['treatments']
                : [];
        final List<String> treatmentsList =
            treatmentsListRaw.map((e) => e.toString()).toList();

        // 4. Save everything to Firestore
        final Map<String, dynamic> plantData = {
          'name': widget.resultData['plant_name']?.toString() ?? 'Plant',
          'scientific_name':
              widget.resultData['scientific_name']?.toString() ?? '',
          'disease_name':
              widget.resultData['disease_name']?.toString() ?? 'Healthy',
          'health_status': widget.resultData['is_healthy'] == true
              ? 'Healthy'
              : 'Needs Attention',
          'image': 'data:image/jpeg;base64,${widget.base64Image}',
          'timestamp': FieldValue.serverTimestamp(),

          // Schedule Logic
          'nextWaterDate': Timestamp.fromDate(nextWaterDate),
          'waterFrequency': frequency,

          // Details
          'description':
              widget.resultData['description']?.toString() ?? '',
          'care_tips': widget.resultData['care_tips']?.toString() ?? '',
          // Dropping 'stats' field to avoid invalid nested values from AI.
          'symptoms': symptomsList,
          'treatments': treatmentsList,
        };

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('my_plants')
            .add(plantData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Added! Next watering scheduled for ${nextWaterDate.day}/${nextWaterDate.month}"),
            backgroundColor: AppTheme.primary,
          ));
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error saving: $e")),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please sign in again to save plants.")),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Normalize raw AI values
    final String plantName = widget.resultData['plant_name']?.toString() ?? 'Plant';
    String rawDisease =
        (widget.resultData['disease_name'] ?? 'Unknown').toString();

    final bool isErrorPayload = plantName.toLowerCase().contains('scan error');

    final bool isNoneDisease =
        rawDisease.toLowerCase() == 'none' || rawDisease.toLowerCase() == 'unknown';
    final bool isHealthyFlag = widget.resultData['is_healthy'] == true;

    String diseaseName =
        (isNoneDisease || isHealthyFlag) ? 'Healthy' : rawDisease;

    // Symptoms can be string or list from AI – normalize to text.
    String symptomsText;
    final dynamic rawSymptoms = widget.resultData['symptoms'];
    if (rawSymptoms == null) {
      symptomsText = 'No symptoms detected.';
    } else if (rawSymptoms is List) {
      symptomsText = rawSymptoms.isEmpty
          ? 'No symptoms detected.'
          : rawSymptoms.join(', ');
    } else {
      symptomsText = rawSymptoms.toString();
    }

    // Treatments: ensure we always have at least one friendly suggestion.
    final dynamic rawTreatments = widget.resultData['treatments'];
    List treatments;
    if (rawTreatments == null) {
      treatments = const ['Monitor the plant and keep usual care.'];
    } else if (rawTreatments is List) {
      treatments = rawTreatments.isEmpty
          ? const ['Monitor the plant and keep usual care.']
          : rawTreatments;
    } else {
      treatments = [rawTreatments.toString()];
    }

    double risk =
        (widget.resultData['risk_level'] ?? (isHealthyFlag ? 0.1 : 0.5))
            .toDouble();

    // If this is an error payload from GeminiService, show a clean error UI.
    if (isErrorPayload) {
      diseaseName = 'Scan failed';
      symptomsText =
          widget.resultData['description']?.toString() ?? 'Something went wrong.';
      treatments = const ['Please try scanning again in a moment.'];
      risk = 0.0;
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Result", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dark Result Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C), 
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                        image: MemoryImage(base64Decode(widget.base64Image)),
                        fit: BoxFit.cover,
                      )
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          diseaseName,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          plantName,
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const Align(
                    alignment: Alignment.bottomRight,
                    child: Text("Just now", style: TextStyle(color: Colors.grey, fontSize: 10)),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            Text("$diseaseName on $plantName", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 8),
            Text(symptomsText, style: TextStyle(color: Colors.grey.shade600, height: 1.5)),
            
            const SizedBox(height: 24),
            const Text("Treatment", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 12),
            ...treatments.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("• ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  Expanded(child: Text(item.toString(), style: TextStyle(color: Colors.grey.shade700, height: 1.4))),
                ],
              ),
            )),
            
            const SizedBox(height: 24),

            // Risk Prediction
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200)
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text("Risk Level", style: TextStyle(fontWeight: FontWeight.bold)),
                   const SizedBox(height: 12),
                   ClipRRect(
                     borderRadius: BorderRadius.circular(8),
                     child: LinearProgressIndicator(
                       value: risk,
                       minHeight: 8,
                       backgroundColor: Colors.green.shade100,
                       valueColor: AlwaysStoppedAnimation<Color>(risk > 0.5 ? Colors.red : Colors.green),
                     ),
                   ),
                   const SizedBox(height: 8),
                   const Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text("Low", style: TextStyle(fontSize: 12, color: Colors.grey)),
                       Text("High", style: TextStyle(fontSize: 12, color: Colors.grey)),
                     ],
                   )
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.green),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                    ),
                    child: const Text("Re-generate", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _addToGarden,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5D8C61), 
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isSaving 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : const Text("Add to Garden", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}