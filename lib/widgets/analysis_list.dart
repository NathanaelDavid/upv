import 'package:flutter/material.dart';

class AnalysisList extends StatelessWidget {
  final List<Map<String, String>> analysisData;

  const AnalysisList({
    super.key,
    required this.analysisData,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        itemCount: analysisData.length,
        itemBuilder: (context, index) {
          final data = analysisData[index];
          return Card(
            child: ListTile(
              title: Text(data['currency']!),
              subtitle: Text(data['analysis']!),
              trailing: Text(data['timestamp']!),
            ),
          );
        },
      ),
    );
  }
}
