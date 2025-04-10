import 'package:flutter/material.dart';

class AnalysisInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const AnalysisInput({
    super.key,
    required this.controller,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Analisis', style: TextStyle(fontSize: 16)),
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Tulis analisis Anda di sini...',
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton(
            onPressed: onSubmit,
            child: const Text('Push'),
          ),
        ),
      ],
    );
  }
}
